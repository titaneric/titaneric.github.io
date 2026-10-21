+++
title = "Shor's Algorithm: Understanding the QFT Interference"
date = 2025-12-17

[taxonomies]
categories = ["Learning"]
tags =  []
+++

### Intuition from the analogy

Think of each possible period as a “clock” with a thumbtack under it. When you apply the QFT, each element of the periodic sequence contributes a little vector toward each candidate period. For wrong periods those vectors point all over and mostly cancel; for the true period they align and add up, so the corresponding thumbtack “travels farthest.” That’s the constructive interference picture Scott uses: only for the true period do all contributions point the same way.

### Setup of the periodic state
We have a function $f(r)=x^r \bmod N$ with period $P$. Prepare a uniform superposition over exponents and their function values:
$$
\frac{1}{\sqrt{M}}\sum_{r=0}^{M-1} |r\rangle\,|f(r)\rangle.
$$
Measuring the second register to a value $y$ leaves the first register in a uniform superposition over all inputs that map to $y$, which are spaced by the period:
$$
\frac{1}{\sqrt{K}}\sum_{k=0}^{K-1} |r_0 + kP\rangle,
$$
where $K\approx M/P$ (limited by the range $0\le r \le M-1$). This encodes the spacing $P$ directly in the input register.

### The QFT action and interference
The Quantum Fourier Transform on $M$ basis states is
$$
|r\rangle \mapsto \frac{1}{\sqrt{M}}\sum_{s=0}^{M-1} e^{2\pi i rs/M}\,|s\rangle.
$$
Applying it to the periodic superposition yields amplitude at output basis \(|s\rangle\):
$$
A_s \;=\; \frac{1}{\sqrt{KM}} \sum_{k=0}^{K-1} e^{2\pi i (r_0 + kP)s/M}
\;=\; \frac{e^{2\pi i r_0 s/M}}{\sqrt{KM}} \sum_{k=0}^{K-1} \left(e^{2\pi i Ps/M}\right)^k.
$$
The inner sum is a geometric series. If $e^{2\pi i Ps/M} = 1$ (i.e., $Ps \equiv 0 \pmod{M}$), then every term points in the same complex direction and the sum equals $K$ — a large, aligned contribution. Otherwise, the terms wrap around the unit circle and largely cancel, giving a small magnitude bounded by
$$
\left|\sum_{k=0}^{K-1} \left(e^{2\pi i Ps/M}\right)^k\right|
\;=\;
\left|\frac{1 - e^{2\pi i KPs/M}}{1 - e^{2\pi i Ps/M}}\right|
\;\text{which is }\ll K \text{ when } e^{2\pi i Ps/M}\ne 1.
$$
This is the precise math for “only the true period’s contributions point the same way.” Peaks occur at $s$ that are integer multiples of $M/P$.

### Worked example with a clean period
- **Setup:** Let $M=16$ and suppose measuring the second register produced a period-$P=4$ superposition:
$$
\frac{1}{\sqrt{4}}\left(|r_0\rangle + |r_0+4\rangle + |r_0+8\rangle + |r_0+12\rangle\right).
$$
- **QFT amplitude:** For any output index $s$,
$$
A_s = \frac{e^{2\pi i r_0 s/16}}{\sqrt{4\cdot16}}
\sum_{k=0}^{3} \left(e^{2\pi i \cdot 4s/16}\right)^k
= \frac{e^{2\pi i r_0 s/16}}{8}
\sum_{k=0}^{3} \left(e^{2\pi i s/4}\right)^k.
$$
- **Constructive cases:** If $s\in\{0,4,8,12\}$, then $e^{2\pi i s/4}=1$ and the sum equals $4$, so $|A_s|=4/8=1/2$. These are large peaks.
- **Destructive cases:** For other $s$, the four phasors point in directions 0°, 90°, 180°, 270° (or similar), summing near zero; hence $|A_s|$ is small.
Measuring after the QFT returns one of $s\in\{0,4,8,12\}$ with high probability. From any such $s$, the spacing $\Delta s=4$ reveals $P = M/\Delta s = 16/4 = 4$.

### Extracting the period in general
- **Observation:** Measured $s$ will be close to some multiple of $M/P$. Writing $s/M \approx j/P$ for integer $j$, use continued fractions to recover $P$. Repeating a few times yields $P$ with high probability.
- **Analogy tie-in:** Each term in the periodic superposition contributes a phasor to each candidate frequency $s$. When $s$ matches the true period’s frequency, all phasors align and add (big thumbtack drift). Else, they point in different directions and cancel (small drift).
> Only for the “true” period do the contributions from different universes all point in the same direction — that’s exactly the geometric-series alignment case above, where $e^{2\pi i Ps/M}=1$.
Perfect — let’s slow down and unpack those two points carefully.

Perfect — let’s slow down and unpack those two points carefully.

---

## 🔹 1. What is \(A_s\)?
When we apply the Quantum Fourier Transform (QFT) to a periodic superposition, we want to know the **amplitude** (the complex weight) of each possible output state \(|s\rangle\).

- Think of the QFT as redistributing the “probability mass” across different output labels \(s\).
- For each output basis state \(|s\rangle\), the QFT assigns a complex number \(A_s\).
- That number \(A_s\) tells us:
  - **Magnitude**: how likely we are to measure \(s\).
  - **Phase**: the direction of the contribution in the complex plane.

So \(A_s\) is just the **amplitude of the output state \(|s\rangle\)** after applying the QFT.  
When we measure, the probability of seeing \(|s\rangle\) is \(|A_s|^2\).

---

## 🔹 2. Why does \(e^{2\pi i P s / M}\) “wrap around the unit circle”?
Let’s decode the term:

$$
e^{2\pi i \theta} = \cos(2\pi \theta) + i \sin(2\pi \theta).
$$

This is Euler’s formula. It represents a point on the **unit circle** in the complex plane:
- Real part = $\cos(2\pi \theta)$.
- Imaginary part = $\sin(2\pi \theta)$.
- Always has magnitude 1.

Now, in our case the term is:

$$
e^{2\pi i P s / M}.
$$

- \(P\) = the period of the sequence.
- \(s\) = the output index we’re testing.
- \(M\) = the total size of the register.

So this term is a complex number of magnitude 1, pointing at an angle \(2\pi \cdot (Ps/M)\).  
If we raise it to powers (like \((e^{2\pi i Ps/M})^k\)), each successive term is another point on the unit circle, rotated by that angle.

---

## 🔹 3. Why does this matter for interference?
The amplitude \(A_s\) involves a sum:

\[
\sum_{k=0}^{K-1} \left(e^{2\pi i Ps/M}\right)^k.
\]

This is a geometric series of points on the unit circle.

- If \(e^{2\pi i Ps/M} = 1\), then every term points in the same direction (all contributions align). The sum is large (\(K\)).
- If \(e^{2\pi i Ps/M} \neq 1\), then each term points in a slightly rotated direction. As you add them, they “wrap around” the circle and mostly cancel out. The sum is small.

This is exactly the constructive vs. destructive interference:
- **True period** → contributions align → big amplitude \(A_s\).
- **Wrong period** → contributions cancel → small amplitude \(A_s\).

---

## 🔹 4. Visual analogy
Imagine walking around a circle:
- If the step size is 0° (i.e., angle = 0), every step lands on the same spot. After \(K\) steps, you’re far from the origin (big sum).
- If the step size is 90°, you walk around the circle: first east, then north, then west, then south. After 4 steps, you’re back at the origin (sum cancels).
- If the step size is some other angle, you spiral around and the contributions partially cancel.

That’s why the exponential term “wraps around the unit circle.”

---

✅ So:
- \(A_s\) = amplitude of output state \(|s\rangle\).
- \(e^{2\pi i Ps/M}\) is a unit circle rotation. If it equals 1, all contributions align (constructive interference). Otherwise, they wrap around and cancel (destructive interference).

---

Would you like me to **draw this out with a simple geometric series example** (say \(M=8, P=4\)) so you can literally see the points on the unit circle adding up? That’s often the moment where interference becomes crystal clear.

## 🎯 The Goal
We want to find the **period** of a sequence like:
\[
x, x^2, x^3, \dots \mod N
\]
This period is the key to factoring \(N\).
The question is: how can a quantum computer help us find that period efficiently?
---
## 🧩 Step 1: What Does “Superposition” Mean Here?
Think of a quantum computer as being able to store **many possibilities at once**.
- A classical computer stores one number at a time.
- A quantum computer can store a **wave-like mixture** of many numbers simultaneously.
So instead of computing just one exponent \(x^r \mod N\), a quantum computer can prepare a state that contains **all exponents at once**.
---
## 🧩 Step 2: The Superposition State
Mathematically, we write this as:
\[
\frac{1}{\sqrt{M}} \sum_{r=0}^{M-1} |r\rangle |x^r \mod N\rangle
\]
Let’s break this down:
- The symbol \(|r\rangle\) means “the quantum computer is storing the number \(r\).”
- The symbol \(|x^r \mod N\rangle\) means “the computer also stores the result of \(x^r \mod N\).”
- The big sum means we’re storing **all values of \(r\) at once**, from 0 up to \(M-1\).
- The factor \(1/\sqrt{M}\) just makes sure probabilities add up correctly.
So this is a **superposition of all exponents and their modular results**.
---
## 🧩 Step 3: Why This Helps
If you measure the second part (the result \(x^r \mod N\)), the state collapses to only those \(r\) values that give the same result.
- Example: If the period is 4, then \(r=0,4,8,12,\dots\) all give the same result.
- After measurement, the quantum computer is left with a superposition of those \(r\) values.
So now we have a quantum state that encodes the **periodic structure** directly.
---
## 🧩 Step 4: Extracting the Period
Here’s where the **Quantum Fourier Transform (QFT)** comes in.
The QFT is a mathematical operation that takes a periodic pattern and turns it into **sharp peaks** at multiples of the period.
Formally, the QFT maps:
\[
|r\rangle \mapsto \frac{1}{\sqrt{M}} \sum_{s=0}^{M-1} e^{2\pi i rs / M} |s\rangle
\]
This looks complicated, but the key idea is:
- It mixes all the values of \(r\) together using complex exponentials (like sine and cosine waves).
- If the input has a hidden period, the output will show spikes at positions related to that period.
---
## 🧩 Step 5: Measurement
After applying the QFT, we measure the quantum state.
- The measurement gives us a number \(s\).
- That number is strongly correlated with the true period \(P\).
- By repeating the process a few times and using a classical trick (continued fractions), we can deduce \(P\).
---
## ✨ Putting It All Together
1. **Superposition**: Store all exponents \(x^r \mod N\) at once.
2. **Measurement**: Collapse to a periodic subset of exponents.
3. **QFT**: Transform the periodic pattern into sharp peaks.
4. **Measurement again**: Read out a number that reveals the period.
This is the “math setup” in plain terms: the quantum computer encodes the periodicity into its wave-like state, and the QFT is the tool that makes the hidden period observable.
---
This is Euler’s formula. It represents a point on the **unit circle** in the complex plane:
- Real part = \(\cos(2\pi \theta)\).
- Imaginary part = \(\sin(2\pi \theta)\).
- Always has magnitude 1.
Now, in our case the term is:
\[
e^{2\pi i P s / M}.
\]
- \(P\) = the period of the sequence.
- \(s\) = the output index we’re testing.
- \(M\) = the total size of the register.
So this term is a complex number of magnitude 1, pointing at an angle \(2\pi \cdot (Ps/M)\).
If we raise it to powers (like \((e^{2\pi i Ps/M})^k\)), each successive term is another point on the unit circle, rotated by that angle.
---
## 🔹 3. Why does this matter for interference?
The amplitude \(A_s\) involves a sum:
\[
\sum_{k=0}^{K-1} \left(e^{2\pi i Ps/M}\right)^k.
\]
This is a geometric series of points on the unit circle.
- If \(e^{2\pi i Ps/M} = 1\), then every term points in the same direction (all contributions align). The sum is large (\(K\)).
- If \(e^{2\pi i Ps/M} \neq 1\), then each term points in a slightly rotated direction. As you add them, they “wrap around” the circle and mostly cancel out. The sum is small.
This is exactly the constructive vs. destructive interference:
- **True period** → contributions align → big amplitude \(A_s\).
- **Wrong period** → contributions cancel → small amplitude \(A_s\).
---
## 🔹 4. Visual analogy
Imagine walking around a circle:
- If the step size is 0° (i.e., angle = 0), every step lands on the same spot. After \(K\) steps, you’re far from the origin (big sum).
- If the step size is 90°, you walk around the circle: first east, then north, then west, then south. After 4 steps, you’re back at the origin (sum cancels).
- If the step size is some other angle, you spiral around and the contributions partially cancel.
That’s why the exponential term “wraps around the unit circle.”
---
✅ So:
- \(A_s\) = amplitude of output state \(|s\rangle\).
- \(e^{2\pi i Ps/M}\) is a unit circle rotation. If it equals 1, all contributions align (constructive interference). Otherwise, they wrap around and cancel (destructive interference).
---
