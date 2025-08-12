# MATLAB GUI for Active Noise Cancellation using Adaptive Filtering

**By Nithil A Rao**

---

## Overview

This project presents a MATLAB GUI application for **Active Noise Cancellation (ANC)** in vehicle cabins using adaptive filtering. It demonstrates key signal processing concepts, adaptive algorithms, and provides a user-friendly interface to explore noise reduction techniques.

---

## What is Active Noise Cancellation?

**Definition:**  
Active Noise Cancellation reduces unwanted sound by generating a second sound wave designed to cancel the first via destructive interference.

**Concept:**  
Two sound waves of equal amplitude but opposite phase combine, effectively cancelling noise.

---

## Applications of ANC

- **Automotive Industry:** Enhances passenger comfort by reducing engine and road noise.  
- **Consumer Electronics:** Noise-cancelling headphones and earphones.  
- **Industrial Settings:** Reduces noise pollution in factories and loud environments.

---

## Overview of the MATLAB GUI Application

- **User Interface:** Load audio files (WAV, MP3) representing engine and cabin noises.  
- **Visualization:** Plot signals for visual analysis to understand noise characteristics.  
- **Real-time Processing:** Apply adaptive filtering for noise reduction using LMS algorithm.

---

## The ANC Algorithm: Adaptive Filtering

Uses the **Least Mean Squares (LMS)** algorithm to iteratively adjust filter coefficients to minimize the error between the desired signal and the noise-cancelled output.

Mathematical update equations:  
- \( y(n) = \mathbf{w}(n-1)^T \mathbf{x}(n) \)  
- \( e(n) = d(n) - y(n) \)  
- \( \mathbf{w}(n) = \mathbf{w}(n-1) + \mu \, e(n) \, \mathbf{x}(n) \)  

Where:  
- \( d(n) \) = desired signal (cabin noise)  
- \( x(n) \) = input signal (engine noise)  
- \( \mu \) = step size (controls convergence speed)  
- \( \mathbf{w}(n) \) = filter coefficients at iteration \( n \)

---

## Example Iterations

| Iteration | \( y(n) \) | \( e(n) \) | \( \mathbf{w}(n) \)           |
|-----------|------------|------------|-------------------------------|
| 1         | 0          | 1          | [0.05, 0]                     |
| 2         | 0.05       | 1.95       | [0.245, 0]                    |
| 3         | 1.27       | 2.72       | [1.18, 0]                     |
| 4         | 2.95       | 2.04       | [1.69, 0]                     |
| 5         | 4.23       | 0.76       | [1.88, 0]                     |
| 6         | 5.64       | 0.35       | [1.98, 0]                     |
| 7         | 6.95       | 0.04       | [2.00, 0]                     |

---

## Signal Processing Concepts

- **Step Rate (\(\mu\))**: Larger values speed convergence but risk instability; smaller values ensure stability but slow adaptation.  
- **Filter Order (M)**: Higher order captures complex noise patterns but needs more computation.

---

## Comparison: LMS Adaptive Filtering vs Destructive Interference

| Aspect               | LMS Adaptive Filtering             | Destructive Interference            |
|----------------------|----------------------------------|-----------------------------------|
| Concept              | Minimizes noise error dynamically | Adds an opposite wave to cancel noise |
| Noise Type           | Handles changing noise patterns   | Works best with steady, predictable noise |
| Flexibility          | Continuously adapts               | Limited to consistent noise        |
| Strength             | Effective for complex noise       | Good for constant noise            |
| Weakness             | Requires time to adapt            | Struggles with varying noise       |

---

## Conclusion

- Developed a MATLAB GUI demonstrating ANC using adaptive filtering.  
- Showcased potential for real-time noise reduction in vehicles.  
- ANC technology can significantly improve acoustic comfort in multiple applications.

---

## References

- [How Ford implements active noise cancellation in cars](https://www.youtube.com/watch?v=Te5UUCXMSIg)  
- [Active Noise Cancellation makes car interiors 90% more silent](https://www.youtube.com/watch?v=pUDu_pyaMtQ)  
- [Innovation: Active Noise Cancellation | New Range Rover Sport](https://www.youtube.com/watch?v=uRNLIDpB4Xs)

---

Thank you!
