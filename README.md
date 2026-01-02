# OTFS-System-from-Scratch
An attempt to build an OTFS system (transmitter + receiver) from scratch in MATLAB

## What's done upto now

- The function pre_OTFS_tx generates random bits, modulates them into a desired modulation scheme and arranges the symbols into blocks according to the OTFS grid size

- The function OTFS_tx generates pilot (centered), guard band and places the symbols in a block into an DD frame. I'm performing this with a nested for loop (has to be improvised). It then converts the DD frame to DT domain, multiplies with a pulse shaping matrix, vectorizes the DT frame and finally adds CP.

## What is to be done

- Implement a wrapper, channel and the receiver.
- Understand different types of OTFS and attempt implementing them
- Look into what kind of noise is to be used. How do I implement different channels? What are other kinds of noise that could be present?