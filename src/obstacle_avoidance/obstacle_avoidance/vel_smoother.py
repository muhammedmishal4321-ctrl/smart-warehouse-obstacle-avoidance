import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist

class VelSmoother(Node):
    def __init__(self):
        super().__init__('vel_smoother')
        self.publisher_ = self.create_publisher(Twist, '/cmd_vel', 10)
        self.subscription = self.create_subscription(
            Twist, '/cmd_vel_raw', self.cmd_callback, 10)

        self.current_linear  = 0.0
        self.current_angular = 0.0
        self.target_linear   = 0.0
        self.target_angular  = 0.0

        self.linear_accel  = 0.02
        self.angular_accel = 0.05

        self.timer = self.create_timer(0.05, self.publish_smooth)

    def cmd_callback(self, msg):
        self.target_linear  = msg.linear.x
        self.target_angular = msg.angular.z

    def publish_smooth(self):
        diff_l = self.target_linear - self.current_linear
        self.current_linear += self.linear_accel * (1 if diff_l > 0 else -1) \
            if abs(diff_l) > self.linear_accel else diff_l

        diff_a = self.target_angular - self.current_angular
        self.current_angular += self.angular_accel * (1 if diff_a > 0 else -1) \
            if abs(diff_a) > self.angular_accel else diff_a

        twist = Twist()
        twist.linear.x  = self.current_linear
        twist.angular.z = self.current_angular
        self.publisher_.publish(twist)

def main(args=None):
    rclpy.init(args=args)
    node = VelSmoother()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()

