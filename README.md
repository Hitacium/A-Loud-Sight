# A Loud Sight

**A Loud Sight** is a game made with **Godot** for a **school project**.  
You play as a **blind person**, moving through labyrinths levels using **sound**.

The project explores how the **TheVoice algorithm**, using different sound distributions (logarithmic or linear), can enhance **spatial perception and orientation for disables**.

---

## What is it ?

In *A Loud Sight*, vision is removed entirely (at least for now, as it is the core gameplay mechanic).  
Instead, the environment is perceived through **audio**. The player has a virtual camera that takes screenshots frequently and converts image data into sound.

For each **pixel**, a sine wave is played with a certain frequency, timing, panning, and amplitude:
- The **frequency** is given by the **Y-axis**, using either the logarithmic or linear distribution
- The **amplitude** is represented by the **brightness** (everything is on grayscale) of the pixel
- The **time and stereo panning** are mapped to the **X-axis**

There is currently **no defined lore** — the game focuses on **statistics and scientific concepts** used for my oral exam.

---

## Tools

- **Godot Engine**
- **TheVoice algorithm**

---