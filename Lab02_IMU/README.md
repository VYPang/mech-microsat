# MECH Microsat: 3D B-Spline Shadow Puzzle and IMU Trajectory

This repository builds a **single 3D B-spline curve** whose orthogonal projections (shadows) form the digits **1**, **2**, and **3**, then turns that curve into synthetic IMU data for dead reckoning in MATLAB.

## What the repo does

- **B-spline shadow editor** (`bspline_shadow_editor.py`): Interactive editor to design a 3D control polygon so that the smooth B-spline curve, when projected onto the XY, YZ, and XZ planes, resembles the digits 1, 2, and 3 respectively. The curve is constrained to lie inside a unit sphere.
- **IMU export** (`generate_imu_from_curve.py`): Reads a saved control-point file (`.npz`), builds the same B-spline, and exports a **rest-to-rest** traversal as tab-delimited accelerometer and gyroscope data. That CSV is compatible with the MATLAB dead-reckoning script.
- **MATLAB visualization** (`ideal_IMU_DCM_script.m`): Integrates the IMU CSV (zero initial position and velocity) and plots the reconstructed 3D trajectory.

All generated files (saved control points, IMU CSV, and optional figures) go into the **`output/`** folder by default.

---

## Workflow: Design a trajectory and visualize it in MATLAB

1. **Create the output folder** (if it does not exist). It will be created automatically the first time you save control points or export IMU data.

2. **Design the curve in the editor**
   - Run the B-spline shadow editor in interactive mode:
     ```bash
     uv run python bspline_shadow_editor.py --edit
     ```
   - In the 2×2 window you get:
     - **XY** (top-left): should look like digit **1**
     - **YZ** (top-right): should look like digit **2**
     - **XZ** (bottom-left): should look like digit **3**
     - **3D** (bottom-right): the full curve inside a unit sphere
   - Drag the **orange control points** in any of the three 2D views (XY, YZ, or XZ). All four views update at once because they share one 3D control polygon.
   - When satisfied, press **`s`** to save the control points. By default they are written to `output/control_points.npz`. You can change the file with `--points-file output/save_123.npz` (or any path) when starting the editor.
   - Press **`r`** to reset to the last loaded (or built-in) set of points.

3. **Export IMU data from the saved curve**
   - From the project root:
     ```bash
     uv run python generate_imu_from_curve.py --input output/control_points.npz --output output/IMU_from_curve.csv
     ```
   - If you saved under a different name (e.g. `output/save_123.npz`), use that path for `--input`. Defaults are `--input output/control_points.npz` and `--output output/IMU_from_curve.csv`.

4. **Visualize in MATLAB**
   - Open `ideal_IMU_DCM_script.m` and ensure `csv_file` points to your IMU CSV (default is `output/IMU_from_curve.csv`).
   - Run the script. Figure 1 shows the **navigation-frame position** (reconstructed 3D trajectory). The curve is the same shape as in the Python editor, up to a rigid translation (the integrator starts at the origin).

5. **Optional: Cross-check in Python**
   - To overlay the dead-reckoned trajectory with the reference spline:
     ```bash
     uv run python generate_imu_from_curve.py visualize output/IMU_from_curve.csv --reference-npz output/control_points.npz --no-show --save output/IMU_from_curve_viz.png
     ```
   - This runs the same dead-reckoning logic as the MATLAB script and plots it together with the reference curve.

---

## How the digit projections are created manually

The digits 1, 2, and 3 are **not** drawn by hand in 2D. They emerge from a **single set of 3D B-spline control points**:

- One array of points **P_i = (X_i, Y_i, Z_i)** defines one continuous 3D curve.
- **XY projection** uses only (X_i, Y_i) → that 2D curve is what looks like “1”.
- **YZ projection** uses (Y_i, Z_i) → that 2D curve is what looks like “2”.
- **XZ projection** uses (X_i, Z_i) → that 2D curve is what looks like “3”.

So you design **one** 3D path; the three digits are its three orthogonal shadows.

**Manual design in the UI**

- You use the **interactive editor** (`bspline_shadow_editor.py --edit`) to **manually adjust each control point** of the B-spline.
- In the 2×2 layout you see the curve and the control polygon (orange dashed line and dots) in:
  - the XY plane (digit 1),
  - the YZ plane (digit 2),
  - the XZ plane (digit 3),
  - and in 3D.
- **Dragging a control point in one 2D view** moves that point in 3D, so the other two 2D views and the 3D view update at the same time. There is no separate “digit 1 path” and “digit 2 path”: there is only one 3D control polygon, and you tune it until the three projections look right.
- To avoid changing one projection while fixing another, you can “stack” points along an axis (e.g. change Z while keeping X and Y fixed so the XY shadow does not move).

After you are happy with the shapes, you save the control points (e.g. to `output/control_points.npz` or `output/save_123.npz`) and then run the IMU export and MATLAB script as in the workflow above.

---

## Scripts and default paths

| Script | Purpose | Default output / input |
|--------|--------|------------------------|
| `bspline_shadow_editor.py` | Edit 3D control points so XY/YZ/XZ look like 1/2/3 | Control points: `output/control_points.npz` (overridable with `--points-file`) |
| `generate_imu_from_curve.py` | Export IMU CSV from a saved .npz | Input: `output/control_points.npz`; output CSV: `output/IMU_from_curve.csv` |
| `generate_imu_from_curve.py visualize ...` | Plot dead-reckoned trajectory (and optional reference spline) | Use `--save` to write an image (e.g. `output/IMU_from_curve_viz.png`) |
| `ideal_IMU_DCM_script.m` | MATLAB dead reckoning and plots | Reads `output/IMU_from_curve.csv` by default |

The `output/` directory is created automatically when you save control points or export the IMU CSV.
