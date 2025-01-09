# OSC Event Timer for Mobile Devices

A simple Flutter application for iPad, iPhone, and other mobile devices that functions as a timer controlled via OSC (Open Sound Control) messages. This app is designed for use in live events and productions where precise timing and remote control are necessary.

## Features

*   **OSC Control:**  Start the timer remotely by sending OSC messages over the local network.
*   **Full-Screen Display:** The timer occupies the entire screen for maximum visibility.
*   **Time Format:** Displays the timer in `MM:SS` format.
*   **Visual Indicators:**
    *   **Yellow Edges (1:00 remaining):**  The screen edges turn yellow when one minute is left on the timer.
    *   **Red Edges (0:15 remaining):** The screen edges turn red when only 15 seconds remain.
    *   **Blinking Red Screen (0:00 reached):** The screen blinks red three times upon reaching zero.
