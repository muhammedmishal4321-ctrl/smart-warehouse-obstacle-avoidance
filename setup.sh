#!/usr/bin/env bash
# ============================================================
#  Smart Warehouse AMR — Quick Setup Script
#  Supports: Laptop (Simulation) and Raspberry Pi (Physical Robot)
# ============================================================
#
#  Usage:
#    chmod +x setup.sh
#    ./setup.sh           # Auto-detects environment
#    ./setup.sh --sim     # Force simulation (laptop) setup
#    ./setup.sh --robot   # Force physical robot (RPi) setup
#
# ============================================================

set -e  # Exit on any error

# ── Colours ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ──────────────────────────────────────────────────
info()    { echo -e "${CYAN}[INFO]${RESET}  $1"; }
success() { echo -e "${GREEN}[OK]${RESET}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; exit 1; }

# ── Banner ───────────────────────────────────────────────────
echo -e ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║    Smart Warehouse AMR — Setup Script                ║${RESET}"
echo -e "${BOLD}${CYAN}║    ROS2 Humble · Gazebo · LiDAR · Nav2               ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
echo -e ""

# ── Detect Architecture ──────────────────────────────────────
ARCH=$(uname -m)
MODE="auto"

# Parse args
for arg in "$@"; do
  case $arg in
    --sim)   MODE="sim";   shift ;;
    --robot) MODE="robot"; shift ;;
    --help)
      echo "Usage: ./setup.sh [--sim | --robot | --help]"
      echo "  --sim    : Laptop/Desktop simulation setup (Gazebo + Nav2)"
      echo "  --robot  : Raspberry Pi physical robot setup"
      exit 0
      ;;
  esac
done

if [ "$MODE" = "auto" ]; then
  if [ "$ARCH" = "aarch64" ]; then
    MODE="robot"
    info "Detected ARM architecture → Raspberry Pi mode"
  else
    MODE="sim"
    info "Detected x86_64 architecture → Simulation (laptop) mode"
  fi
fi

# ── Check Ubuntu 22.04 ───────────────────────────────────────
if [ -f /etc/os-release ]; then
  . /etc/os-release
  if [[ "$VERSION_ID" != "22.04" ]]; then
    warn "This project is tested on Ubuntu 22.04. You have: $PRETTY_NAME"
    warn "Proceeding anyway — some packages may differ."
  fi
fi

# ── Check ROS2 Humble ────────────────────────────────────────
info "Checking ROS2 Humble..."
if ! command -v ros2 &>/dev/null; then
  info "ROS2 not found. Installing ROS2 Humble..."
  sudo apt update
  sudo apt install -y software-properties-common curl
  sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
    http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
    | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
  sudo apt update

  if [ "$MODE" = "sim" ]; then
    sudo apt install -y ros-humble-desktop
  else
    sudo apt install -y ros-humble-ros-base
  fi
  success "ROS2 Humble installed"
else
  success "ROS2 Humble already installed"
fi

# Source ROS2
source /opt/ros/humble/setup.bash

# ── Simulation-Only Dependencies ────────────────────────────
if [ "$MODE" = "sim" ]; then
  info "Installing simulation dependencies (Nav2, SLAM, Gazebo)..."
  sudo apt install -y \
    ros-humble-navigation2 \
    ros-humble-nav2-bringup \
    ros-humble-slam-toolbox \
    ros-humble-gazebo-ros-pkgs \
    ros-humble-robot-state-publisher \
    ros-humble-joint-state-publisher \
    ros-humble-rviz2
  success "Simulation dependencies installed"
fi

# ── Physical Robot Dependencies ──────────────────────────────
if [ "$MODE" = "robot" ]; then
  info "Installing physical robot dependencies..."
  sudo apt install -y \
    ros-humble-rplidar-ros \
    python3-pip
  pip3 install pyserial --break-system-packages
  success "Physical robot dependencies installed"

  # RPLiDAR udev rule
  info "Setting up RPLiDAR udev rule..."
  if [ ! -f /etc/udev/rules.d/99-rplidar.rules ]; then
    echo 'KERNEL=="ttyUSB*", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE:="0666", GROUP="dialout"' \
      | sudo tee /etc/udev/rules.d/99-rplidar.rules > /dev/null
    sudo udevadm control --reload-rules && sudo udevadm trigger
    success "RPLiDAR udev rule added (no more sudo chmod!)"
  else
    success "RPLiDAR udev rule already exists"
  fi

  # Arduino udev rule
  info "Setting up Arduino udev rule..."
  if ! groups | grep -q dialout; then
    sudo usermod -aG dialout "$USER"
    warn "Added $USER to dialout group. Please log out and back in."
  fi
fi

# ── Python pip Dependencies ──────────────────────────────────
info "Installing Python dependencies from requirements.txt..."
pip3 install -r requirements.txt --break-system-packages
success "Python dependencies installed"

# ── Build Workspace ──────────────────────────────────────────
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
info "Building ROS2 workspace at: $WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

source /opt/ros/humble/setup.bash
colcon build --symlink-install
success "Workspace built successfully"

# Source the workspace
source "$WORKSPACE_DIR/install/setup.bash"

# ── Done ─────────────────────────────────────────────────────
echo -e ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║  ✅  Setup Complete!                                  ║${RESET}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
echo -e ""

if [ "$MODE" = "sim" ]; then
  echo -e "${BOLD}Next steps (Simulation):${RESET}"
  echo -e "  1. source install/setup.bash"
  echo -e "  2. Run Gazebo → see README.md for full terminal commands"
else
  echo -e "${BOLD}Next steps (Physical Robot):${RESET}"
  echo -e "  1. source install/setup.bash"
  echo -e "  2. Upload firmware/motor_control.ino to Arduino Mega"
  echo -e "  3. Run: ros2 launch rplidar_ros rplidar_a1_launch.py"
  echo -e "  4. Run: ros2 run obstacle_avoidance serial_bridge"
  echo -e "  5. Run: ros2 run obstacle_avoidance vel_smoother"
  echo -e "  6. Run: ros2 run obstacle_avoidance avoid"
fi

echo -e ""
echo -e "  📖 Full documentation: README.md"
echo -e ""
