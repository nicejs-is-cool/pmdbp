using System;
using RogueElements;

namespace BPE
{
    /// <summary>A single dungeon tile. The ID decides its type (and color in the mesh).</summary>
    public class DungeonTile : ITile
    {
        public const int Wall = 0;
        public const int Floor = 1;
        public const int Water = 2;

        public DungeonTile() { ID = Wall; }
        public DungeonTile(int id) { ID = id; }
        protected DungeonTile(DungeonTile other) { ID = other.ID; }

        public int ID { get; set; }

        public ITile Copy() => new DungeonTile(this);

        public bool TileEquivalent(ITile other) => other is DungeonTile t && t.ID == ID;
    }

    /// <summary>
    /// The map RogueElements generates into.
    /// MapGen creates it through Activator.CreateInstance, so it needs a parameterless constructor.
    /// </summary>
    public class DungeonGenContext : ITiledGenContext, IRoomGridGenContext, IPlaceableGenContext
    {
        public IRandom Rand { get; private set; }
        public FloorPlan RoomPlan { get; private set; }
        public GridPlan GridPlan { get; private set; }

        public DungeonTile[][] Tiles { get; private set; }

        public ITile RoomTerrain => new DungeonTile(DungeonTile.Floor);
        public ITile WallTerrain => new DungeonTile(DungeonTile.Wall);

        public bool TilesInitialized => Tiles != null;
        public int Width => Tiles.Length;
        public int Height => Tiles[0].Length;
        public bool Wrap => false;

        public void InitSeed(ulong seed) => Rand = new ReRandom(seed);

        public void FinishGen() { }

        public void InitPlan(FloorPlan plan) => RoomPlan = plan;

        public void InitGrid(GridPlan plan) => GridPlan = plan;

        public void CreateNew(int width, int height, bool wrap = false)
        {
            Tiles = new DungeonTile[width][];
            for (int x = 0; x < width; x++)
            {
                Tiles[x] = new DungeonTile[height];
                for (int y = 0; y < height; y++)
                    Tiles[x][y] = new DungeonTile(DungeonTile.Wall);
            }
        }

        // Only walls block. Water is walkable (it just gets its own color).
        public bool TileBlocked(Loc loc) => Tiles[loc.X][loc.Y].ID == DungeonTile.Wall;

        public bool TileBlocked(Loc loc, bool diagonal) => TileBlocked(loc);

        public ITile GetTile(Loc loc) => Tiles[loc.X][loc.Y];

        public bool CanSetTile(Loc loc, ITile tile) => true;

        public bool TrySetTile(Loc loc, ITile tile)
        {
            if (!CanSetTile(loc, tile))
                return false;
            Tiles[loc.X][loc.Y] = (DungeonTile)tile;
            return true;
        }

        public void SetTile(Loc loc, ITile tile)
        {
            if (!TrySetTile(loc, tile))
                throw new InvalidOperationException("Can't place tile!");
        }
    }
}
