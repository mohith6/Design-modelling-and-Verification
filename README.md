# Design Modelling and Verification of safety railway networks of tain signalling systems

## Overview
This Promela model simulates a train signaling and movement system with four stations (A, B, C, D) and tunnels connecting them. It models the flow of trains, control of signaling systems, and synchronization of train movements across the stations and tunnels. The model includes:
- Stations: Manage train entry, exit, and signaling.
- Tunnels: Control train movement, restricting the number of trains in the tunnels.
- SignalBoxes: Manage track-side signals to ensure safe train movements.
- Safety and Integrity: Ensure that no tunnel holds more than one train at a time and handle train and signal interactions correctly.
- Concurrency: The system ensures correct behavior when multiple stations interact concurrently.

## Key Features
- Signal Handling: Detailed signal management with Go, Stop, Clear, and Blocked states.
- Train Movement: Properly manages train entry and exit from tunnels, ensuring only one train is in a tunnel at a time.
- Concurrency Management: Synchronizes train and signal movements across multiple stations to prevent race conditions.
- Safety and Integrity: Ensures that tunnels do not hold more than one train and verifies no deadlocks occur.
- LTL Properties: Includes properties to verify safety, prevent deadlocks, and ensure valid signal states.

## System Workflows
- Trains are introduced before specific stations (e.g., train T1 is introduced before station C, and train T2 is introduced before station A).
- Trains move through the tunnels when the signal is Go or Clear, and stop when the signal is Stop or Blocked.
- Each signal box manages the signaling system based on track occupancy. If the track is clear, it signals Clear; if occupied, it signals Go or Blocked accordingly.
- The system includes a safety process to ensure that only one train can be in a tunnel at a time.
- The integrity check prevents tunnels from being overbooked

## Running the Model
Steps to Run
- Install SPIN: Download and install SPIN.
- Run SPIN: spin -a spin10.pml
- Complie C code: After SPIN generates C code, Complie it
  gcc -o pan pan.c
- Run the Model: ./pan -a

SPIN will perform the Model Checking and verifies systems satifies the LTL properties



