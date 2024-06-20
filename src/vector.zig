//! A simple vector type.

const std = @import("std");

pub const Vec2 = VecN(f32, 2);
pub const Vec3 = VecN(f32, 3);
pub const Vec4 = VecN(f32, 4);

pub fn VecN(comptime T: type, comptime N: comptime_int) type {
    return extern struct {
        const Self = @This();
        pub const size = N;
        data: @Vector(N, T) = @splat(0),

        pub fn x(self: Self) T {
            return self.data[0];
        }

        pub fn y(self: Self) T {
            if (N < 2) @compileError("VecN does not have a y component");

            return self.data[1];
        }

        pub fn z(self: Self) T {
            if (N < 3) @compileError("VecN does not have a z component");

            return self.data[2];
        }

        pub fn w(self: Self) T {
            if (N < 4) @compileError("VecN does not have a w component");

            return self.data[3];
        }

        pub fn init(values: [N]T) Self {
            return .{ .data = values };
        }

        pub fn extend(other: VecN(T, N - 1)) Self {
            var data: [N]T = undefined;
            for (0..N - 1) |i|
                data[i] = other.data[i];

            data[N - 1] = 0;
            return init(data);
        }

        /// Splat a value across all elements of the vector.
        pub fn splat(value: T) Self {
            return .{ .data = @splat(value) };
        }

        pub fn add(lhs: Self, rhs: Self) Self {
            return .{ .data = lhs.data + rhs.data };
        }

        pub fn sub(lhs: Self, rhs: Self) Self {
            return .{ .data = lhs.data - rhs.data };
        }

        pub fn dot(lhs: Self, rhs: Self) T {
            return @reduce(.Add, lhs.data * rhs.data);
        }

        pub fn divide(lhs: Self, rhs: Self) Self {
            return .{ .data = lhs.data / rhs.data };
        }

        /// Scale the vector by a scalar.
        pub fn scale(lhs: Self, rhs: T) Self {
            return .{ .data = lhs.data * @as(@TypeOf(lhs.data), @splat(rhs)) };
        }

        /// Returns the length of the vector squared.
        /// This is useful for comparing the relative lengths of vectors without computing a square root.
        pub fn lenSq(self: Self) T {
            return self.dot(self);
        }

        pub fn len(self: Self) T {
            return std.math.sqrt(self.lenSq());
        }

        pub fn format(
            self: Self,
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            const _fmt = if (fmt.len == 0) "d" else fmt;

            try writer.print("Vec{}(", .{N});
            try std.fmt.formatType(self.data, _fmt, options, writer, 0);
            try writer.print(")", .{});
        }

        test scale {
            const v1 = Vec3{ .data = .{ 1.0, 2.0, 3.0 } };
            const v2 = v1.scale(2.0);

            try std.testing.expectApproxEqRel(@as(f32, 2.0), v2.data[0], std.math.floatEps(f32));
            try std.testing.expectApproxEqRel(@as(f32, 4.0), v2.data[1], std.math.floatEps(f32));
            try std.testing.expectApproxEqRel(@as(f32, 6.0), v2.data[2], std.math.floatEps(f32));
        }

        test dot {
            const v1 = Vec3{ .data = .{ 1.0, 2.0, 3.0 } };
            const v2 = Vec3{ .data = .{ 4.0, 5.0, 6.0 } };
            const v3 = v1.dot(v2);
            try std.testing.expectApproxEqRel(@as(f32, 32.0), v3, std.math.floatEps(f32));
        }

        test len {
            const v = Vec3{ .data = .{ 3.0, 4.0, 0.0 } };
            try std.testing.expectApproxEqRel(@as(f32, 5.0), v.len(), std.math.floatEps(f32));
        }

        test add {
            const v1 = Vec3{ .data = .{ 1.0, 2.0, 3.0 } };
            const v2 = Vec3{ .data = .{ 4.0, 5.0, 6.0 } };
            const v3 = v1.add(v2);
            try std.testing.expectApproxEqRel(@as(f32, 5.0), v3.data[0], std.math.floatEps(f32));
            try std.testing.expectApproxEqRel(@as(f32, 7.0), v3.data[1], std.math.floatEps(f32));
            try std.testing.expectApproxEqRel(@as(f32, 9.0), v3.data[2], std.math.floatEps(f32));
        }
    };
}
