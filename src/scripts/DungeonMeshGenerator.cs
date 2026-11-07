using Godot;
using RogueElements;

namespace BPE
{
	/// <summary>
	/// Generates a dungeon with RogueElements and turns it into one ArrayMesh + trimesh collision.
	///  - Every non-wall tile becomes a floor quad, colored by tile type.
	///  - Wall tiles get no geometry of their own. Instead, a wall quad is emitted on every
	///    tile EDGE where a walkable tile touches a wall tile (or the map border).
	/// </summary>
	[Tool]
	public partial class DungeonMeshGenerator : Node3D
	{
		[Export] public bool GenerateOnReady { get; set; } = true;
		[Export] public long Seed { get; set; } = 0;

		[Export] public float CellSize { get; set; } = 1.0f;
		[Export] public float WallHeight { get; set; } = 2.0f;
		[ExportToolButton("Regenerate Dungeon")] public Callable Regenerate => Callable.From(Generate);


		[ExportGroup("Tile Colors")]
		[Export] public Color FloorColor { get; set; } = new Color(0.55f, 0.45f, 0.35f);
		[Export] public Color WaterColor { get; set; } = new Color(0.2f, 0.4f, 0.85f);
		[Export] public Color WallColor { get; set; } = new Color(0.6f, 0.6f, 0.65f);
		[Export] public Color UnknownColor { get; set; } = new Color(1f, 0f, 1f);
		
		public DungeonGenContext Context { get; private set; }

		private Node3D _generated;

		// For a floor tile at (x, z), each entry describes one of its 4 edges:
		//  (dx, dz)  neighbor offset to test for a wall
		//  normal    direction the wall quad faces (into the room)
		//  left/right corner offsets of the edge, as seen from the room side
		// Corners are ordered so the quad is clockwise (Godot's front face) when seen from `normal`.
		private static readonly (int dx, int dz, Vector3 normal, Vector2I left, Vector2I right)[] Edges =
		{
			(0, -1, Vector3.Back,    new Vector2I(0, 0), new Vector2I(1, 0)), // north edge
			(0,  1, Vector3.Forward, new Vector2I(1, 1), new Vector2I(0, 1)), // south edge
			(-1, 0, Vector3.Right,   new Vector2I(0, 1), new Vector2I(0, 0)), // west edge
			(1,  0, Vector3.Left,    new Vector2I(1, 0), new Vector2I(1, 1)), // east edge
		};

		public override void _EnterTree()
		{
			// MapGen swallows exceptions thrown inside steps and reports them here.
			GenContextDebug.OnError += OnGenError;
		}

		public override void _ExitTree()
		{
			GenContextDebug.OnError -= OnGenError;
		}

		public override void _Ready()
		{
			if (GenerateOnReady)
				Generate();
		}

		private static void OnGenError(System.Exception ex) => GD.PrintErr("RogueElements: ", ex.ToString());

		
		public void Generate()
		{
			ulong seed = Seed != 0 ? (ulong)Seed : MathUtils.Rand.NextUInt64();
			GD.Print($"Dungeon seed: {seed}");

			Context = BuildLayout().GenMap(seed);
			BuildMeshAndCollision(Context);
		}

		// RogueElements layout (grid of rooms, halls, plus some water)
		private static MapGen<DungeonGenContext> BuildLayout()
		{
			var layout = new MapGen<DungeonGenContext>();

			layout.GenSteps.Add(-4, new InitGridPlanStep<DungeonGenContext>(1)
			{
				CellX = 6,
				CellY = 4,
				CellWidth = 9,
				CellHeight = 9,
			});

			var path = new GridPathBranch<DungeonGenContext>
			{
				RoomRatio = new RandRange(70),
				BranchRatio = new RandRange(0, 50),
				GenericRooms = new SpawnList<RoomGen<DungeonGenContext>>
				{
					{ new RoomGenSquare<DungeonGenContext>(new RandRange(4, 8), new RandRange(4, 8)), 10 },
					{ new RoomGenRound<DungeonGenContext>(new RandRange(5, 9), new RandRange(5, 9)), 10 },
				},
				GenericHalls = new SpawnList<PermissiveRoomGen<DungeonGenContext>>
				{
					{ new RoomGenAngledHall<DungeonGenContext>(50), 10 },
				},
			};
			layout.GenSteps.Add(-4, path);

			layout.GenSteps.Add(-2, new DrawGridToFloorStep<DungeonGenContext>());

			// 1 tile of wall padding around the map
			layout.GenSteps.Add(0, new DrawFloorToTileStep<DungeonGenContext>(1));

			// Water, painted over wall tiles
			var water = new DungeonTile(DungeonTile.Water);
			layout.GenSteps.Add(3, new PerlinWaterStep<DungeonGenContext>(
				new RandRange(35), 3, water, new MapTerrainStencil<DungeonGenContext>(false, true, false, false), 1));
			layout.GenSteps.Add(4, new DropDiagonalBlockStep<DungeonGenContext>(new DungeonTile(DungeonTile.Water)));
			layout.GenSteps.Add(4, new EraseIsolatedStep<DungeonGenContext>(new DungeonTile(DungeonTile.Water)));

			return layout;
		}

		// Mesh + collision
		private void BuildMeshAndCollision(DungeonGenContext map)
		{
			if (_generated != null)
			{
				_generated.QueueFree();
				_generated = null;
			}

			var st = new SurfaceTool();
			st.Begin(Mesh.PrimitiveType.Triangles);

			int quads = 0;
			for (int x = 0; x < map.Width; x++)
			{
				for (int z = 0; z < map.Height; z++)
				{
					int id = map.Tiles[x][z].ID;
					if (id == DungeonTile.Wall)
						continue;

					// Floor quad
					Vector3 a = Corner(x, z, 0);
					Vector3 b = Corner(x + 1, z, 0);
					Vector3 c = Corner(x + 1, z + 1, 0);
					Vector3 d = Corner(x, z + 1, 0);
					AddQuad(st, a, b, c, d, Vector3.Up, ColorFor(id));
					quads++;

					// Wall quads on every edge that borders a wall / the map border
					foreach (var e in Edges)
					{
						if (!IsWall(map, x + e.dx, z + e.dz))
							continue;

						Vector3 bl = Corner(x + e.left.X, z + e.left.Y, 0);
						Vector3 br = Corner(x + e.right.X, z + e.right.Y, 0);
						Vector3 tl = Corner(x + e.left.X, z + e.left.Y, WallHeight);
						Vector3 tr = Corner(x + e.right.X, z + e.right.Y, WallHeight);
						AddQuad(st, tl, tr, br, bl, e.normal, WallColor);
						quads++;
					}
				}
			}

			_generated = new Node3D { Name = "GeneratedDungeon" };
			AddChild(_generated);

			if (quads == 0)
				return;

			ArrayMesh mesh = st.Commit();

			var material = new StandardMaterial3D
			{
				VertexColorUseAsAlbedo = true,
				CullMode = BaseMaterial3D.CullModeEnum.Disabled, // walls visible from both sides
			};
			mesh.SurfaceSetMaterial(0, material);

			_generated.AddChild(new MeshInstance3D { Name = "Mesh", Mesh = mesh });

			var shape = mesh.CreateTrimeshShape();
			shape.BackfaceCollision = true; // can't be walked through from behind
			var body = new StaticBody3D { Name = "Collision" };
			body.AddChild(new CollisionShape3D { Shape = shape });
			_generated.AddChild(body);
		}

		private static bool IsWall(DungeonGenContext map, int x, int z)
		{
			if (x < 0 || z < 0 || x >= map.Width || z >= map.Height)
				return true; // out of bounds counts as wall
			return map.Tiles[x][z].ID == DungeonTile.Wall;
		}

		private Vector3 Corner(int x, int z, float height) => new Vector3(x * CellSize, height, z * CellSize);

		private Color ColorFor(int id)
		{
			switch (id)
			{
				case DungeonTile.Floor: return FloorColor;
				case DungeonTile.Water: return WaterColor;
				case DungeonTile.Wall: return WallColor;
				default: return UnknownColor;
			}
		}

		/// <summary>Corners must be clockwise as seen from the side `normal` points to.</summary>
		private static void AddQuad(SurfaceTool st, Vector3 tl, Vector3 tr, Vector3 br, Vector3 bl, Vector3 normal, Color color)
		{
			st.SetColor(color);
			st.SetNormal(normal);

			st.AddVertex(tl);
			st.AddVertex(tr);
			st.AddVertex(br);

			st.AddVertex(tl);
			st.AddVertex(br);
			st.AddVertex(bl);
		}
	}
}
