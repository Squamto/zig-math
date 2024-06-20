const std = @import("std");
const Vec = @import("vector.zig").VecN;

pub fn QuadMatrix(comptime T: type, comptime N: comptime_int) type {
    return extern struct {
        const Self = @This();
        const VecType = Vec(T, N);
        const LowerVecType = Vec(T, N - 1);

        data: [N]VecType = .{VecType{}} ** N,

        pub fn set(self: *Self, row: usize, col: usize, value: T) void {
            self.data[row].data[col] = value;
        }

        pub fn get(self: Self, row: usize, col: usize) T {
            return self.data[row].data[col];
        }

        pub fn transpose(mat: Self) Self {
            var result = Self{};
            for (0..N) |i| for (0..N) |j| result.set(i, j, mat.get(j, i));

            return result;
        }

        pub fn identity(value: T) Self {
            var result = Self{};
            for (0..N) |i| result.set(i, i, value);

            return result;
        }

        pub fn add(rhs: Self, lhs: Self) Self {
            var result = Self{};
            for (0..N) |i| result.data[i] = rhs.data[i].add(lhs.data[i]);

            return result;
        }

        pub fn multiply(rhs: Self, lhs: Self) Self {
            var result = Self{};

            const lhs_transposed = Self.transpose(lhs);

            for (0..N) |i| for (0..N) |j| result.set(i, j, rhs.data[i].dot(lhs_transposed.data[j]));
            return result;
        }

        pub fn vec_multiply(mat: Self, vec: VecType) VecType {
            var result = VecType{};
            for (0..N) |i| result.data[i] = mat.data[i].dot(vec);

            return result;
        }

        pub fn scale(scalar: LowerVecType) Self {
            var result = Self.identity(1);

            for (0..N - 1) |i| result.set(i, i, scalar.data[i]);

            return result;
        }

        pub fn translate(offset: LowerVecType) Self {
            var row: VecType = undefined;
            for (0..LowerVecType.size) |i| row.data[i] = offset.data[i];
            row.data[N - 1] = 1;

            var result = Self.identity(1);
            result.data[N - 1] = row;

            return result;
        }

        pub const Axis = enum { X, Y, Z };
        pub fn rotate(axis: Axis, value: T) Self {
            comptime if (N != 4) @compileError("Only 4x4 matrices are implemented");

            const c = std.math.cos(value);
            const s = std.math.sin(value);

            return switch (axis) {
                .X => res: {
                    var result: Self = undefined;
                    result.data[0] = VecType{ .data = .{ 1, 0, 0, 0 } };
                    result.data[1] = VecType{ .data = .{ 0, c, -s, 0 } };
                    result.data[2] = VecType{ .data = .{ 0, s, c, 0 } };
                    result.data[3] = VecType{ .data = .{ 0, 0, 0, 1 } };
                    break :res result;
                },
                .Y => res: {
                    var result: Self = undefined;
                    result.data[0] = VecType{ .data = .{ c, 0, s, 0 } };
                    result.data[1] = VecType{ .data = .{ 0, 1, 0, 0 } };
                    result.data[2] = VecType{ .data = .{ -s, 0, c, 0 } };
                    result.data[3] = VecType{ .data = .{ 0, 0, 0, 1 } };
                    break :res result;
                },
                .Z => res: {
                    var result: Self = undefined;
                    result.data[0] = VecType{ .data = .{ c, -s, 0, 0 } };
                    result.data[1] = VecType{ .data = .{ s, c, 0, 0 } };
                    result.data[2] = VecType{ .data = .{ 0, 0, 1, 0 } };
                    result.data[3] = VecType{ .data = .{ 0, 0, 0, 1 } };
                    break :res result;
                },
            };
        }

        pub fn rotate_euler(x: T, y: T, z: T) Self {
            comptime if (N != 4) @compileError("Only 4x4 matrices are implemented");

            const cx = std.math.cos(x);
            const sx = std.math.sin(x);
            const cy = std.math.cos(y);
            const sy = std.math.sin(y);
            const cz = std.math.cos(z);
            const sz = std.math.sin(z);

            var result: Self = undefined;
            result.data[0] = VecType{ .data = .{ cy * cz, cy * sz, -sy, 0 } };
            result.data[1] = VecType{ .data = .{ sx * sy * cz - cx * sz, sx * sy * sz + cx * cz, sx * cy, 0 } };
            result.data[2] = VecType{ .data = .{ cx * sy * cz + sx * sz, cx * sy * sz - sx * cz, cx * cy, 0 } };
            result.data[3] = VecType{ .data = .{ 0, 0, 0, 1 } };

            return result;
        }

        pub fn rotate_euler_Vec(euler: LowerVecType) Self {
            return Self.rotate_euler(euler.data[0], euler.data[1], euler.data[2]);
        }

        pub fn perspective(fov: T, aspect: T, near: T, far: T) Self {
            comptime if (N != 4) @compileError("Only 4x4 matrices are implemented");

            const tan_half_fov = std.math.tan(fov / 2.0);

            var result = Self.identity(1);
            result.set(0, 0, 1.0 / (aspect * tan_half_fov));
            result.set(1, 1, -1.0 / tan_half_fov);
            result.set(2, 2, -(far + near) / (far - near));
            result.set(2, 3, -1.0);
            result.set(3, 2, -(2.0 * far * near) / (far - near));
            result.set(3, 3, 0.0);

            return result;
        }
    };
}

const expect = std.testing.expect;

test "Matrix identity" {
    const Matrix = QuadMatrix(f32, 4);
    const identity = Matrix.identity(1);
    try expect(identity.data[0].data[0] == 1.0);
    try expect(identity.data[1].data[1] == 1.0);
    try expect(identity.data[2].data[2] == 1.0);
    try expect(identity.data[3].data[3] == 1.0);
}

test "Matrix transpose" {
    const Matrix = QuadMatrix(f32, 4);
    var mat = Matrix{};
    mat.set(0, 0, 1);
    mat.set(0, 1, 2);
    mat.set(0, 2, 3);
    mat.set(0, 3, 4);

    const t = mat.transpose();

    try expect(t.get(0, 0) == 1.0);
    try expect(t.get(1, 0) == 2.0);
    try expect(t.get(2, 0) == 3.0);
    try expect(t.get(3, 0) == 4.0);
}

test "Matrix add" {
    const Matrix = QuadMatrix(f32, 4);
    var mat1 = Matrix{};
    mat1.set(0, 0, 1);
    mat1.set(0, 1, 2);
    mat1.set(0, 2, 3);
    mat1.set(0, 3, 4);

    var mat2 = Matrix{};
    mat2.set(0, 0, 5);
    mat2.set(0, 1, 6);
    mat2.set(0, 2, 7);
    mat2.set(0, 3, 8);

    const sum = Matrix.add(mat1, mat2);

    try expect(sum.get(0, 0) == 6.0);
    try expect(sum.get(0, 1) == 8.0);
    try expect(sum.get(0, 2) == 10.0);
    try expect(sum.get(0, 3) == 12.0);
}

test "Matrix multiply" {
    const Matrix = QuadMatrix(f32, 2);

    var mat1 = Matrix{};
    mat1.set(0, 0, 1);
    mat1.set(0, 1, 2);
    mat1.set(1, 0, 3);
    mat1.set(1, 1, 4);

    var mat2 = Matrix{};
    mat2.set(0, 0, 5);
    mat2.set(0, 1, 6);
    mat2.set(1, 0, 7);
    mat2.set(1, 1, 8);

    const product = Matrix.multiply(mat1, mat2);

    try expect(product.get(0, 0) == 19.0);
    try expect(product.get(0, 1) == 22.0);
    try expect(product.get(1, 0) == 43.0);
    try expect(product.get(1, 1) == 50.0);
}
