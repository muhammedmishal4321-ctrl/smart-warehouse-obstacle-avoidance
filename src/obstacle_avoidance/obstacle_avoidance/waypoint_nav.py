import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from nav_msgs.msg import Odometry
import math

class WaypointNavigator(Node):
    def __init__(self):
        super().__init__('waypoint_nav')
        self.publisher_ = self.create_publisher(Twist, '/cmd_vel', 10)
        self.subscription = self.create_subscription(
            Odometry, '/odom', self.odom_callback, 10)

        # Your warehouse waypoints (x, y)
        self.waypoints = [
            (2.0, 0.0),
            (2.0, 3.0),
            (0.0, 3.0),
            (0.0, 0.0),  # back to start
        ]
        self.current_waypoint = 0
        self.x   = 0.0
        self.y   = 0.0
        self.yaw = 0.0
        self.goal_threshold = 0.3  # how close = "reached"

    def odom_callback(self, msg):
        self.x = msg.pose.pose.position.x
        self.y = msg.pose.pose.position.y

        q = msg.pose.pose.orientation
        siny = 2.0 * (q.w * q.z + q.x * q.y)
        cosy = 1.0 - 2.0 * (q.y * q.y + q.z * q.z)
        self.yaw = math.atan2(siny, cosy)

        self.navigate()

    def navigate(self):
        if self.current_waypoint >= len(self.waypoints):
            self.get_logger().info('All waypoints reached!')
            self.publisher_.publish(Twist())
            return

        goal_x, goal_y = self.waypoints[self.current_waypoint]
        dx = goal_x - self.x
        dy = goal_y - self.y
        distance = math.sqrt(dx**2 + dy**2)

        if distance < self.goal_threshold:
            self.get_logger().info(f'Reached waypoint {self.current_waypoint}!')
            self.current_waypoint += 1
            return

        target_angle = math.atan2(dy, dx)
        angle_error  = math.atan2(
            math.sin(target_angle - self.yaw),
            math.cos(target_angle - self.yaw))

        twist = Twist()
        twist.angular.z = 1.0 * angle_error
        twist.linear.x  = 0.2 if abs(angle_error) < 0.5 else 0.0
        self.publisher_.publish(twist)

def main(args=None):
    rclpy.init(args=args)
    node = WaypointNavigator()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
