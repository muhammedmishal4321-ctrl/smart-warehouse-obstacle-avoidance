import rclpy
from rclpy.node import Node
from sensor_msgs.msg import LaserScan
from geometry_msgs.msg import Twist

class ObstacleAvoider(Node):
    def __init__(self):
        super().__init__('obstacle_avoidance')
        self.subscription = self.create_subscription(
            LaserScan, '/scan', self.scan_callback, 10)
        self.publisher_ = self.create_publisher(Twist, '/cmd_vel_raw', 10)

        self.safe_distance    = 0.5   # stop and turn
        self.caution_distance = 1.0   # slow down and steer
        self.forward_speed    = 0.2
        self.turn_speed       = 0.5

    def scan_callback(self, msg):
        ranges = msg.ranges
        total  = len(ranges)

        # Split scan into 3 zones
        front = min(ranges[int(total*0.42): int(total*0.58)] or [float('inf')])
        left  = min(ranges[int(total*0.58): int(total*0.75)] or [float('inf')])
        right = min(ranges[int(total*0.25): int(total*0.42)] or [float('inf')])

        twist = Twist()

        if front < self.safe_distance:
            # Obstacle close — stop and turn away from closer side
            twist.linear.x  = 0.0
            twist.angular.z = self.turn_speed if left > right else -self.turn_speed

        elif front < self.caution_distance:
            # Obstacle in caution zone — slow and steer
            twist.linear.x  = self.forward_speed * 0.5
            twist.angular.z = 0.3 if left > right else -0.3

        else:
            # All clear
            twist.linear.x  = self.forward_speed
            twist.angular.z = 0.0

        self.publisher_.publish(twist)

def main(args=None):
    rclpy.init(args=args)
    node = ObstacleAvoider()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
