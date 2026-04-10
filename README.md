
```markdown
<div align="center">

# 🤖 Smart Warehouse AMR
### Dynamic Obstacle Avoidance · SLAM Mapping · Nav2 Navigation

<br>

[![ROS2](https://img.shields.io/badge/ROS2-Humble_Hawksbill-22314E?style=for-the-badge&logo=ros&logoColor=white)](https://docs.ros.org/en/humble/)
[![Python](https://img.shields.io/badge/Python-3.10-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Gazebo](https://img.shields.io/badge/Gazebo-11-FF6600?style=for-the-badge)](https://gazebosim.org/)
[![Arduino](https://img.shields.io/badge/Arduino-Mega_2560-00979D?style=for-the-badge&logo=arduino&logoColor=white)](https://www.arduino.cc/)
[![License](https://img.shields.io/badge/License-MIT-2EA043?style=for-the-badge)](LICENSE)

<br>

**A fully functional Autonomous Mobile Robot (AMR) built for smart warehouse environments.** Features real-time LiDAR-based obstacle avoidance, SLAM mapping, and Nav2 goal navigation —  
running on both **Gazebo simulation** and a **physical Raspberry Pi robot**.

<br>

[📦 Quick Setup](#-quick-setup) · [🚀 Run the Project](#-running-the-project) · [🔧 Hardware](#-hardware) · [🧠 How It Works](#-how-it-works)

</div>

---

## 📌 Project Overview

| Feature | Simulation | Physical Robot |
|---|---|---|
| **Platform** | Ubuntu 22.04 (Laptop/Desktop) | Raspberry Pi 4 (Ubuntu 22.04 aarch64) |
| **Sensor** | Simulated LiDAR (Gazebo plugin) | RPLiDAR A1 (360°) |
| **Motor Control** | Gazebo Differential Drive Plugin | L298N H-Bridge + Arduino Mega |
| **Navigation** | Nav2 + SLAM Toolbox | `avoid.py` + `vel_smoother.py` |
| **Communication** | ROS2 Topics | ROS2 + Serial @ 57600 baud |

> The same ROS2 nodes (`avoid.py`, `vel_smoother.py`) run on **both** Gazebo and the physical robot — true simulation-to-hardware portability.

---

## 📁 Repository Structure

```
smart-warehouse-obstacle-avoidance/
├── 📄 setup.sh                 ← One-shot setup script (auto-detects laptop vs RPi)
├── 📄 requirements.txt         ← Python pip dependencies
├── 📄 README.md
├── 📂 firmware/
│   └── motor_control.ino       ← Arduino Mega motor PWM controller
├── 📂 docs/
│   └── images/                 ← Screenshots & GIFs for README
└── 📂 src/
    ├── 📦 obstacle_avoidance/  ← Core ROS2 package (shared: sim + physical)
    │   └── obstacle_avoidance/
    │       ├── avoid.py        ← Zone-based obstacle avoidance node
    │       ├── vel_smoother.py ← Velocity ramping for smooth motion
    │       └── waypoint_nav.py ← Odometry-based waypoint navigator
    └── 📦 two_wheel_robot/     ← Simulation ROS2 package
        ├── config/
        │   ├── nav2_params.yaml← Nav2 stack parameters
        │   └── slam_params.yaml← SLAM Toolbox parameters
        ├── launch/
        │   └── spawn_robot.launch.py ← Spawns robot into Gazebo
        ├── maps/
        │   ├── my_warehouse_map.pgm  ← SLAM-generated occupancy grid
        │   └── my_warehouse_map.yaml ← Map metadata file
        ├── urdf/
        │   └── two_wheel_robot.urdf  ← Robot description (diff drive + LiDAR)
        └── worlds/
            └── warehouse.world       ← Gazebo warehouse environment
```

---

## 🧠 How It Works

### System Architecture

```
╔══════════════════════════════════════════════════════════╗
║                    RASPBERRY PI 4                        ║
║                                                          ║
║  [RPLiDAR A1] ──► /scan ──► [avoid.py] ──► /cmd_vel_raw  ║
║                                  │                       ║
║                         [vel_smoother.py]                ║
║                                  │                       ║
║                          /cmd_vel ──► [serial_bridge.py] ║
║                                              │           ║
╚══════════════════────────────────────────────┼────────────╝
                                               │ USB Serial (57600 baud)
                                               ▼
                                        [ARDUINO MEGA]
                                               │
                              ┌────────────────┴──────────────┐
                              ▼                               ▼
                          LEFT MOTOR                     RIGHT MOTOR
                        (L298N OUT1/2)                 (L298N OUT3/4)
```

### ROS2 Topic Flow

```
/scan (LaserScan)
    └──► avoid.py ──────────► /cmd_vel_raw (Twist)
                                    └──► vel_smoother.py ──► /cmd_vel (Twist)
                                                                  └──► serial_bridge.py ──► Arduino
```

### Zone-Based Obstacle Avoidance

```
        ┌─────────────────┐
        │   FRONT ZONE    │  42%–58% of scan
        │  (stop & turn)  │
   ┌────┴────┐       ┌────┴────┐
   │  LEFT   │ ROBOT │  RIGHT  │
   │ 58%–75% │       │ 25%–42% │
   └─────────┘       └─────────┘
```

| Distance | Behaviour |
|---|---|
| `< 0.5 m` (safe) | Full stop → turn toward open side |
| `0.5 – 1.0 m` (caution) | Slow to 50% speed → gentle steer |
| `> 1.0 m` (clear) | Full speed forward |

---

## 🔧 Hardware

### Components

| Component | Model | Role |
|---|---|---|
| Single Board Computer | Raspberry Pi 4 (4 GB RAM) | Main robot brain |
| Microcontroller | Arduino Mega 2560 | PWM motor control |
| Motor Driver | L298N Dual H-Bridge | Drives 2× DC motors |
| LiDAR Sensor | RPLiDAR A1 | 360° obstacle detection |
| Motors | 2× DC Geared Motors | Differential drive |
| Chassis | Circular (custom) | Robot base + caster wheel |

### Wiring

```
Arduino Mega → L298N Motor Driver
──────────────────────────────────────
Pin 5  → IN1        Left Motor  → OUT1, OUT2
Pin 6  → IN2        Right Motor → OUT3, OUT4
Pin 7  → IN3
Pin 8  → IN4        12V Adapter → 12V terminal
Pin 9  → ENA        L298N GND   → Arduino GND
Pin 10 → ENB        L298N 5V    → Arduino 5V

Power & Communication
──────────────────────────────────────
RPi USB-A  → Arduino Mega   (serial @ 57600 baud)
RPi USB-A  → RPLiDAR A1     (scan data)
RPi        powered by 5V USB-C adapter (separate supply)
```

---

## 💻 Software Stack

| Software | Version | Purpose |
|---|---|---|
| Ubuntu | 22.04 LTS | OS (laptop + RPi) |
| ROS2 | Humble Hawksbill | Robotics middleware |
| Gazebo | 11 | 3D physics simulation |
| RViz2 | — | Visualisation |
| slam_toolbox | — | SLAM mapping |
| Nav2 | — | Autonomous navigation stack |
| rplidar_ros | ros2 branch | RPLiDAR A1 driver |
| Python | 3.10 | ROS2 node scripting |
| pyserial | ≥ 3.5 | Arduino serial comms |

---

## 📦 Quick Setup

### Option A — Automated (Recommended)

```bash
git clone [https://github.com/muhammedmishal4321-ctrl/smart-warehouse-obstacle-avoidance.git](https://github.com/muhammedmishal4321-ctrl/smart-warehouse-obstacle-avoidance.git)
cd smart-warehouse-obstacle-avoidance

chmod +x setup.sh
./setup.sh          # Auto-detects laptop vs Raspberry Pi
```

The script will:
- Detect your hardware (x86_64 → simulation, aarch64 → robot)
- Install ROS2 Humble + all dependencies
- Build the workspace with `colcon build`
- Print exactly what to run next

### Option B — Manual

#### 1. Install ROS2 Humble

```bash
sudo apt update && sudo apt install ros-humble-desktop -y
source /opt/ros/humble/setup.bash
```

#### 2. Install ROS2 Packages

```bash
# Simulation (laptop)
sudo apt install -y \
  ros-humble-navigation2 ros-humble-nav2-bringup \
  ros-humble-slam-toolbox ros-humble-gazebo-ros-pkgs \
  ros-humble-robot-state-publisher ros-humble-joint-state-publisher

# Physical robot (Raspberry Pi — additional)
pip3 install -r requirements.txt --break-system-packages
```

#### 3. Build the Workspace

```bash
cd smart-warehouse-obstacle-avoidance
colcon build --symlink-install
source install/setup.bash
```

---

## 🚀 Running the Project

### 🖥️ Simulation (Gazebo + RViz)

Open **6 terminals** in the workspace directory. Run `source install/setup.bash` in each first.

```bash
# Terminal 1 — Launch Gazebo warehouse
gazebo src/two_wheel_robot/worlds/warehouse.world \
  --verbose -s libgazebo_ros_init.so -s libgazebo_ros_factory.so

# Terminal 2 — Spawn robot into Gazebo
ros2 run gazebo_ros spawn_entity.py \
  -file src/two_wheel_robot/urdf/two_wheel_robot.urdf \
  -entity robot1 -x 0 -y 0 -z 0.1

# Terminal 3 — Robot State Publisher
ros2 run robot_state_publisher robot_state_publisher \
  --ros-args \
  -p robot_description:="$(cat src/two_wheel_robot/urdf/two_wheel_robot.urdf)" \
  -p use_sim_time:=true

# Terminal 4 — Joint State Publisher
ros2 run joint_state_publisher joint_state_publisher \
  --ros-args -p use_sim_time:=true

# Terminal 5 — Obstacle Avoidance (start smoother first)
ros2 run obstacle_avoidance vel_smoother &
ros2 run obstacle_avoidance avoid

# Terminal 6 — RViz Visualisation
rviz2
```

### 🗺️ SLAM Mapping (while simulation is running)

```bash
# Launch SLAM
ros2 run slam_toolbox async_slam_toolbox_node --ros-args \
  -p use_sim_time:=true \
  -p odom_frame:=odom \
  -p base_frame:=base_link \
  -p scan_topic:=/scan \
  -p mode:=mapping

# Save the map when complete
ros2 run nav2_map_server map_saver_cli -f src/two_wheel_robot/maps/my_warehouse_map
```

### 🧭 Nav2 Autonomous Navigation

```bash
ros2 launch nav2_bringup bringup_launch.py \
  use_sim_time:=true \
  map:=$(pwd)/src/two_wheel_robot/maps/my_warehouse_map.yaml \
  params_file:=$(pwd)/src/two_wheel_robot/config/nav2_params.yaml
```

In RViz: set **Fixed Frame** → `map` → click **2D Pose Estimate** → click **2D Goal Pose**.

### 🤖 Physical Robot (Raspberry Pi)

SSH into the RPi and run in 4 terminals (after `source install/setup.bash`):

```bash
# Terminal 1 — RPLiDAR (give it a gentle flick to start the motor)
ros2 launch rplidar_ros rplidar_a1_launch.py

# Terminal 2 — Serial bridge to Arduino
ros2 run obstacle_avoidance serial_bridge

# Terminal 3 — Velocity smoother
ros2 run obstacle_avoidance vel_smoother

# Terminal 4 — Obstacle avoidance brain
ros2 run obstacle_avoidance avoid
```

> **Note:** If you see `Permission denied: /dev/ttyUSB0`, run `setup.sh` which adds the udev rule automatically. Or manually: `sudo chmod 777 /dev/ttyUSB0`

---

## 📡 Core Nodes Reference

### `avoid.py`
Subscribes to `/scan` → publishes to `/cmd_vel_raw`

| Parameter | Value | Description |
|---|---|---|
| `safe_distance` | 0.5 m | Full stop + turn threshold |
| `caution_distance` | 1.0 m | Slow down + steer threshold |
| `forward_speed` | 0.2 m/s | Normal cruising speed |
| `turn_speed` | 0.5 rad/s | Turn angular velocity |

### `vel_smoother.py`
Subscribes to `/cmd_vel_raw` → publishes smooth `/cmd_vel`

| Parameter | Value |
|---|---|
| Linear acceleration | 0.02 m/s² per tick |
| Angular acceleration | 0.05 rad/s² per tick |
| Timer rate | 20 Hz (50 ms) |

### `waypoint_nav.py`
Subscribes to `/odom` → publishes to `/cmd_vel`  
Navigates through a hardcoded list of (x, y) waypoints using odometry feedback.

### Arduino `motor_control.ino`
Receives 2 bytes over serial (left_byte, right_byte):

```
127 = stop  |  > 127 = forward  |  < 127 = reverse
Deadzone: 124–130 (prevents motor hum)
Speed limit: 1.5× multiplier (75% max, safe for warehouse)
```

---

## 🐛 Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| LiDAR buffer overflow on RPi | Pre-compiled binary bug | Build `rplidar_ros` from source (see setup.sh) |
| LiDAR timeout / not spinning | USB power sag | Give rotor a gentle flick; unplug Arduino temporarily |
| `/map` frame not found | AMCL not running | Use `bringup_launch.py`, not `navigation_launch.py` |
| Robot doesn't move | `vel_smoother` not running | Always start `vel_smoother` **before** `avoid` |
| `Permission denied /dev/ttyACM0` | Linux USB permissions | `sudo chmod 666 /dev/ttyACM0` or run `setup.sh` |
| One motor not working | Thin wire on L298N | Replace with thicker wire of equal gauge |
| Robot drifts left/right | Motor speed mismatch | Adjust `right_limit` multiplier in `motor_control.ino` |
| `colcon build` fails | Missing ROS2 packages | Re-run `./setup.sh` or install deps manually |

---

## 📊 Project Status

| Feature | Status |
|---|---|
| URDF robot model | ✅ Complete |
| Gazebo warehouse world | ✅ Complete |
| Zone-based obstacle avoidance | ✅ Complete |
| Velocity smoother | ✅ Complete |
| SLAM map generation | ✅ Complete |
| Nav2 navigation (simulation) | ✅ Working |
| Physical robot assembly | ✅ Complete |
| RPLiDAR A1 integration | ✅ Complete |
| Arduino motor control | ✅ Complete |
| Physical obstacle avoidance | ✅ Complete |
| Demo video / GIFs | 🔲 Pending |

---

## 🔮 Future Work

- [ ] Integrate Nav2 goal navigation on the physical robot
- [ ] Add camera-based object detection for package identification
- [ ] Implement multi-robot coordination for fleet management
- [ ] Waypoint-based delivery path planning
- [ ] Battery monitoring and auto-docking

---

## 👥 Team

| Name | Register No | Role |
|---|---|---|
| Nafeesath Liyana Latheef | 23BCARI117 | Simulation, Hardware Integration, ROS2 |
| Muhammed Mishal | — | Hardware Assembly, Testing |

  
**Institution:** Yenepoya Institute of Arts, Science, Commerce and Management  
**Program:** BCA — Artificial Intelligence, Machine Learning, Robotics & IoT

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

<div align="center">

Made with ❤️ at **Yenepoya Institute** · BCA AIML Robotics 2026

</div>
```
