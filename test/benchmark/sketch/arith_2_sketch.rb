# { sketch_1: Int -> Int, sketch_2: (Int, Int, Int) -> Int }
def sketch_1(x, y, z)
    # { sketch_1: Int -> Int, sketch_2: (Int, Int, Int) -> Int, x: Int, y: Int, z: Int }
    w = [x, y, z].reduce(0) {
        # { sketch_1: Int -> Int, sketch_2: (Int, Int, Int) -> Int, x: Int, y: Int, z: Int, w: Int, acc: Int, n: Int }
        |acc, n| acc += _? * _?
    }
    
    # { sketch_1: Int -> Int, sketch_2: (Int, Int, Int) -> Int, x: Int, y: Int, z: Int, w: Int }
    _?
end

def sketch_2(y)
    # { sketch_1: Int -> Int, sketch_2: (Int, Int, Int) -> Int, y: Int }
    sketch_1(1, 2, _?)
end
