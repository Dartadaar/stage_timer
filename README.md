# OSC Event Timer

A simple Flutter application for iOS and Android devices that functions as an event timer, controlled via OSC (Open Sound Control).

## Controlling the Timer via OSC

This application listens for OSC messages on **port 21600**. You can control the timer using the following commands:

**1. Start a Timer:**

   Send an OSC message with the following structure:

   *   **Address:** `/timer`
   *   **Argument:** A string representing the desired time in `mm:ss` format.

   **Example:** To start a 5-minute timer, send the following OSC message:

   *   **Address:** `/timer`
   *   **Argument:** `"05:00"` (Note the quotation marks as it's a string argument)

   The actual OSC string you would send might look like this (including null terminators common in OSC): /timer\x00\x00,s\x00\x0005:00\x00


**2. Clear the Timer:**

To reset and clear the timer, send the following OSC message:

*   **Address:** `/timer`
*   **Argument:** `"clear"`

**Example:** The actual OSC string you would send might look like this: /timer\x00\x00,s\x00\x00clear\x00\x00\x00


**Important Notes:**

*   The application listens on UDP port **21600**.
*   The argument for the `/timer` command is a string. Make sure your OSC sending software is sending string arguments.
