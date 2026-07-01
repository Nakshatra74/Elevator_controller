# 4-Floor Elevator Controller (Verilog)

A fully synthesizable, robust Finite State Machine (FSM) implementation of a 4-floor elevator controller. This project utilizes the **SCAN Algorithm** to efficiently handle multiple simultaneous floor requests, sweeping up and down without erratic directional changes.

## 🚀 Features

* **SCAN Algorithm Implementation:** The elevator continues in its current direction of travel, servicing all pending requests in that path before reversing direction.
* **Asynchronous Request Latching:** Momentary button presses are captured and stored in memory (`latched_req`) until the floor is successfully serviced.
* **Combinational Lookahead Logic:** Evaluates active requests dynamically to determine if there are pending stops above or below the current position.
* **Hardware Bounds Checking:** Defensive logic prevents the elevator floor counter from underflowing below Floor 0 or overflowing above Floor 3.
* **Simulated Door Timers:** Integrates a realistic delay cycle for passenger loading/unloading while clearing the serviced request on the final clock tick.

## 🛠️ Architecture and State Machine

The core of the design is a 3-state FSM working in tandem with a directional memory flag (`moving_up`).

1. **`IDLE` (Decision State):** 
   * Stops the motor and evaluates the `latched_req` register.
   * Prioritizes servicing the current floor. 
   * If the current floor is clear, it checks the lookahead logic (`req_above` / `req_below`) to maintain its directional sweep or reverse course.
2. **`MOVING` (Transition State):**
   * Increments or decrements the `current_floor` counter based on the `dir` signal.
   * Immediately drops back to `IDLE` after moving one floor to allow for "on-the-way" dynamic pickups.
3. **`DOOR` (Service State):**
   * Halts the motor (`dir = STOP`) and asserts the `door_open` signal.
   * Runs a countdown timer (default 4 clock cycles).
   * Clears the serviced floor from the `latched_req` memory on the final clock cycle before closing the doors.

## 🔌 Module Interface (Ports)

| Port Name | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `clk` | Input | 1-bit | System clock. |
| `rst` | Input | 1-bit | Active-high synchronous reset. Returns elevator to Floor 0, IDLE state. |
| `req` | Input | 4-bit | Floor request buttons mapped as `{F3, F2, F1, F0}`. |
| `current_floor` | Output | 2-bit | Indicates the physical location of the elevator (`00` to `11`). |
| `door_open` | Output | 1-bit | Asserted high (`1`) when doors are open for passenger transfer. |
| `dir` | Output | 2-bit | Motor direction: `00` (Stop), `01` (Up), `10` (Down). |

## ⚙️ Simulation Notes & Real-World Behavior

When writing testbenches for this module, it is important to simulate momentary button presses accurately. 

**The "Held Button" Phenomenon:** 
Because the module features continuous request latching (`latched_req <= (latched_req | req) & ~clear_req;`), if a testbench holds a bit high on the `req` bus *after* the doors have closed for that floor, the controller will interpret this as a passenger immediately pressing the button again. It will re-latch the request and return to that floor on its next directional sweep, mimicking real-world behavior. 

To avoid phantom pickups in simulation, ensure `req` pulses high for only a few clock cycles to simulate a standard human button press.

## 📝 Usage / Instantiation

```verilog
elevator_controller uut (
    .clk(clk),
    .rst(rst),
    .req(req),
    .current_floor(current_floor),
    .door_open(door_open),
    .dir(dir)
);
