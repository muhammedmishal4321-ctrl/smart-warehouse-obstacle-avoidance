from launch import LaunchDescription
from launch_ros.actions import Node
import os

def generate_launch_description():

    urdf_file = os.path.expanduser(
        '~/digital_twin_ws/src/two_wheel_robot/urdf/two_wheel_robot.urdf')

    return LaunchDescription([
        Node(
            package='gazebo_ros',
            executable='spawn_entity.py',
            arguments=[
                '-entity', 'two_wheel_robot',
                '-file', urdf_file],
            output='screen'
        )
    ])
