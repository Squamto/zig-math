const std = @import("std");

pub const VecN = @import("vector.zig").VecN;

pub const Vec2 = VecN(f32, 2);
pub const Vec3 = VecN(f32, 3);
pub const Vec4 = VecN(f32, 4);

pub const QuadMatrix = @import("matrix.zig").QuadMatrix;

pub const Matrix4 = QuadMatrix(f32, 4);

pub fn degToRad(value: anytype) @TypeOf(value) {
    return value / 360.0 * 2.0 * std.math.pi;
}

pub fn radToDeg(value: anytype) @TypeOf(value) {
    return value / (2.0 * std.math.pi) * 360.0;
}

test "Vector" {
    _ = VecN;
}
