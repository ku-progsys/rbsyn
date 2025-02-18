# { sketch_1: Int -> Int, sketch_2: Int -> Int }
def sketch_1(x)
    # { sketch_1: Int -> Int, sketch_2: Int -> Int, x: Int }
    foo = 10

    # { sketch_1: Int -> Int, sketch_2: Int -> Int, x: Int, foo: Int }
    x + _? + _? + 1
end

def sketch_2(y, z)
    # { sketch_1: Int -> Int, sketch_2: (Int, Int) -> Int, y: Int, z: Int }
    sketch_1(_? + 3)
end
