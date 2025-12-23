+++
title = "Elliptic Curve Point Addition: Mathematical Foundations for Cryptographic Key Exchange"
date = 2025-12-23

[taxonomies]
categories = ["Notes"]
tags =  ["cryptography", "math"]
+++

I've read the fantastic [Animated Elliptic Curve](https://curves.xargs.org) exposition and wanted to write up my own detailed notes on the mathematics of elliptic curve point addition and its application to cryptographic key exchange.

Elliptic curve point addition is the algebraic operation that gives elliptic curves their group structure. That group law—together with scalar multiplication (repeated addition)—is the mathematical foundation for modern public-key protocols such as Elliptic Curve Diffie–Hellman (ECDH) and the key exchanges used in TLS 1.3.

This note presents a detailed derivation of the point-addition formulas for curves in short Weierstrass form, explains how the formulas are evaluated in a finite field, and adds practical facts and examples drawn from the [Animated Elliptic Curve](https://curves.xargs.org) exposition, including small toy curves (Curve61) and references to real-world curves (Curve25519).

## Elliptic curves and point addition

**Conventions.** We work with the short Weierstrass equation for an elliptic curve:
$$y^2 = x^3 + a x + b$$
over either the real numbers (for geometric intuition) or the finite field $\mathbb{F}_p$ (for cryptographic use). Points are written as $P=(x_1,y_1)$ and $Q=(x_2,y_2)$; the point at infinity (the group identity) is denoted $\mathcal{O}$.

**Overview.** The geometric rule for addition is:
- Draw the line through $P$ and $Q$ (or the tangent at $P$ when $P=Q$).
- Find the third intersection $R'$ of that line with the curve.
- Reflect $R'$ across the $x$-axis to get the sum $R=P+Q$.

### Geometric derivation and algebraic formulas

1) Adding distinct points ($P\neq Q$).

Let the line through $P$ and $Q$ have slope $\lambda$ and equation
$$y = \lambda x + \nu.$$
The slope is the usual slope of a secant:
$$\lambda = \frac{y_2 - y_1}{x_2 - x_1}$$
when working over the reals, and in $\mathbb{F}_p$ we interpret division via modular inverse:
$$\lambda = (y_2 - y_1)\cdot (x_2 - x_1)^{-1}\pmod p,$$
where $(x_2-x_1)^{-1}$ is the [multiplicative inverse in $\mathbb{F}_p$](https://curves.xargs.org/#division-multiplicative-inverse).

Substitute $y=\lambda x+\nu$ into $y^2=x^3+ax+b$ and expand to obtain a cubic polynomial in $x$:
$$\begin{aligned}
(\lambda x + \nu)^2 &= x^3 + a x + b \\
\lambda^2 x^2 + 2\lambda\nu x + \nu^2 &= x^3 + a x + b.
\end{aligned}
$$
Bring all terms to one side:
$$
\begin{aligned}
x^3 - \lambda^2 x^2 + (a - 2\lambda\nu) x + (b - \nu^2) = 0.
\end{aligned}
$$

Remember we have [Vieta's formulas](https://en.wikipedia.org/wiki/Vieta%27s_formulas) relating the roots to the coefficients of a polynomial.:

> Given a cubic equation $ P(x) = ax^3 + bx^2 + cx + d = 0 $, the roots $ x_1, x_2, x_3 $ satisfy:
> $$ x_1 + x_2 + x_3 = -\frac{b}{a} $$
> $$ x_1 x_2 + x_1 x_3 + x_2 x_3 = \frac{c}{a} $$
> $$ x_1 x_2 x_3 = -\frac{d}{a} $$

Applying Vieta's formulas to our cubic (with $a=1$, $b=-\lambda^2$, $c=a - 2\lambda\nu$, $d=b - \nu^2$) gives the relations among the three $x$-coordinates of the intersection points $P$, $Q$, and $R'$:

$$x_1+x_2+x_3 = \lambda^2,$$
$$x_1x_2 + x_1x_3 + x_2x_3 = a - 2\lambda\nu,$$
$$x_1x_2x_3 = \nu^2 - b.$$
The first identity yields the commonly used formula
$$ x_3 = \lambda^2 - x_1 - x_2. $$

To obtain $y_3$, compute the $y$-value of the third intersection $R'$ using the line: $y_3' = \lambda x_3 + \nu$. Since $\nu = y_1 - \lambda x_1$ we have $y_3' = \lambda(x_3 - x_1) + y_1$, and reflecting across the $x$-axis gives the sum
$$ y_3 = -y_3' = \lambda(x_1 - x_3) - y_1. $$

These identities hold over $\mathbb{F}_p$ when every division is interpreted as multiplication by an inverse.

2) Doubling ($P=Q$).

When $P=Q$ the secant becomes the tangent. Implicit differentiation of $y^2=x^3+ax+b$ gives
$$\frac{dy}{dx} = \frac{3x^2+a}{2y},$$
so at $(x_1,y_1)$ the tangent slope is
$$\lambda = \frac{3x_1^2 + a}{2y_1}.$$
Substituting into the formulas $ x_3 = \lambda^2 - x_1 - x_2 $ (with $x_2=x_1$) and $y_3 = \lambda(x_1 - x_3) - y_1$ yields
$$ x_3 = \lambda^2 - 2x_1,\qquad y_3 = \lambda(x_1 - x_3) - y_1. $$

This concludes the derivation of [Point Addition](https://curves.xargs.org/#point-addition) formulas.

## Finite-field arithmetic (practical cryptography)

Elliptic curves used in cryptography are defined over prime fields $\mathbb{F}_p$. To adapt the real-number formulas we perform every operation modulo $p$.

- The field $\mathbb{F}_p$ is the set $\{0,1,\dots,p-1\}$ with addition and multiplication taken modulo $p$.
- Additive inverse: $-n\equiv p-n \pmod p$.
- Multiplicative inverse: for nonzero $b$ there exists $b^{-1}\in\mathbb{F}_p$ with $b\cdot b^{-1}\equiv1\pmod p$.
- Square roots and residues: for $n\in\mathbb{F}_p$ a square root is an element $y\in\mathbb{F}_p$ satisfying $$y^2 \equiv n \pmod p.$$ If such a $y$ exists then $n$ is a **quadratic residue** modulo $p$ and the two square roots are $y$ and $-y$ (unless $y\equiv0$). If no such $y$ exists then $n$ is a **quadratic non-residue** modulo $p$.

In the elliptic-curve equation $y^2\equiv x^3+ax+b\pmod p$ define$$r(x) \equiv x^3 + ax + b \pmod p.$$ There exists an $\mathbb{F}_p$-rational point with $x$-coordinate $x$ exactly when $r(x)$ is a quadratic residue, i.e. when there exists $y\in\mathbb{F}_p$ with $y^2\equiv r(x)\pmod p$. In that case the two points are $(x,y)$ and $(x,-y)$.

The point-addition formulas are the same as in the real case, but every arithmetic operation is performed in $\mathbb{F}_p$. Concretely, for $P\neq Q$:
$$\lambda \equiv (y_2-y_1)\cdot (x_2-x_1)^{-1} \pmod p,$$
$$x_3 \equiv \lambda^2 - x_1 - x_2 \pmod p,$$
$$y_3 \equiv \lambda(x_1 - x_3) - y_1 \pmod p,$$
and for doubling:$$\lambda \equiv (3x_1^2 + a)\cdot (2y_1)^{-1} \pmod p.$$ 

All final $x_3,y_3$ values are reduced modulo $p$.

## Example: Point addition on a toy curve Curve61

Let $p = 61$ and consider the elliptic curve E defined over the prime field $\mathbb{F}_p$ by
$$E : y^2 \equiv x^3 + 9x + 1 \pmod{p}.$$
We write $E(\mathbb{F}_p)$ for the set of $\mathbb{F}_p$-rational points on $E$, i.e. the pairs $(x,y)$ with $x,y \in \mathbb{F}_p$ satisfying the curve equation together with the point at infinity $O$.

For each $x \in \mathbb{F}_p$ define the right-hand side value
$$r(x) \equiv x^3 + 9x + 1 \pmod p.$$
The set of points in $E(\mathbb{F}_p)$ with $x$-coordinate equal to $x$ is nonempty precisely when there exists $y \in \mathbb{F}_p$ with $$y^2 \equiv r(x) \pmod p.$$ In that case the two solutions are $y$ and $-y$ (negatives taken modulo $p$), which give the two points with the same $x$-coordinate.

Example computations:

- For x = 0:
  $$\begin{aligned}
  r(0) &\equiv 0^3 + 9\cdot0 + 1 \equiv 1 \pmod{61}.
  \end{aligned}$$
  One square root is $y \equiv 1$ since $1 \cdot 1 \equiv 1 \pmod{61}$; the other is $y \equiv -1 \equiv 60 \pmod{61}$. Thus $(0,1),(0,60) \in E(\mathbb{F}_{61})$.

- For x = 1:
  $$\begin{aligned}
  r(1) &\equiv 1^3 + 9\cdot1 + 1 \equiv 11 \pmod{61}.
  \end{aligned}$$
  Here 11 is a quadratic non-residue in $\mathbb{F_{61}}$, so there is no $y \in \mathbb{F_{61}}$ with $y^2 \equiv 11$; there is no point of $E(\mathbb{F}_{61})$ with $x=1$.

- For x = 2:
  $$\begin{aligned}
  r(2) &\equiv 2^3 + 9\cdot2 + 1 \equiv 27 \pmod{61}.
  \end{aligned}$$
  One square root is $y \equiv 24$ since $24 \cdot 24 \equiv 576 \equiv 27 \pmod{61}$; the other is $y \equiv -24 \equiv 37 \pmod{61}$. Thus $(2,24),(2,37) \in E(\mathbb{F}_{61})$.

Proceeding similarly for each $x \in \mathbb{F}_p$ produces the full set $E(\mathbb{F}_p)$. The group law on $E(\mathbb{F}_p)$ uses the addition formulas given above, with all arithmetic interpreted modulo $p$.

### Worked numeric example: adding two points on Curve61

We present a step-by-step modular computation of $P+Q$ with
$$p=61,\qquad E: y^2\equiv x^3 + 9x + 1\pmod{61},$$
and take the two points
$$P=(2,24),\qquad Q=(0,1).$$

1) Compute the slope $\lambda$ for distinct points $P\neq Q$:
$$\lambda \equiv (y_Q-y_P)\cdot(x_Q-x_P)^{-1} \pmod{61}.$$

$$y_Q-y_P = 1-24 \equiv 1-24 \equiv -23 \equiv 38 \pmod{61}.$$

$$x_Q-x_P = 0-2 \equiv -2 \equiv 59 \pmod{61}.$$
We need the inverse of $59$ modulo $61$. Since $59\equiv -2$, its inverse is the inverse of $-2$, which is $-31\equiv 30$ because $(-2)\cdot(-31)=62\equiv1\pmod{61}$. Thus $59^{-1}\equiv 30$. 
So
$$\lambda \equiv 38\cdot 30 \equiv 1140 \equiv 42 \pmod{61}.$$

2) Compute $x_3$:
$$x_3 \equiv \lambda^2 - x_P - x_Q \equiv 42^2 - 2 - 0 \equiv 1764 - 2 \equiv 1762\equiv 54 \pmod{61}.$$

3) Compute $y_3$ using $y_3 \equiv \lambda(x_P - x_3) - y_P$:
$$x_P - x_3 = 2-54 \equiv -52 \equiv 9 \pmod{61}$$
$$\lambda(x_P-x_3) \equiv 42\cdot 9 =378 \equiv 12 \pmod{61}$$
$$y_3 \equiv 12 - 24 \equiv -12 \equiv 49 \pmod{61}.$$

Therefore the sum is
$$P+Q = (54,49) \in E(\mathbb{F}_{61}).$$

One may verify directly that $(54,49)$ satisfies the curve equation modulo 61, and that adding $P$ and $Q$ by the geometric/tangent method produces this same point.

## Efficient scalar multiplication

Scalar multiplication $nP$ (adding $P$ to itself $n$ times) is the expensive primitive. A naive loop costs O(n) additions; efficient methods use doubling plus addition (binary double-and-add) to achieve O(log n) elliptic-curve additions. For example, if we need to calculate $13P$, we could pre-compute $1P$, $4P$, and $8P$ via doubling, then add the results:
$$
\begin{aligned}
2P &= P + P,\\\\
4P &= 2P + 2P,\\\\
8P &= 4P + 4P,\\\\
13P &= 8P + 4P + P.
\end{aligned}
$$

## Cryptographic key exchange using elliptic curves

Elliptic-curve Diffie–Hellman (ECDH) is the standard key-exchange primitive built from the group law on an elliptic curve. The protocol is simple to state and relies on two related hardness assumptions:

- Elliptic Curve Discrete Logarithm Problem (ECDLP): given $P$ and $Q=kP$ for unknown integer $k$, recover $k$.
- Computational Diffie–Hellman (CDH) on the curve: given $P$, $A=k_aP$, and $B=k_bP$, compute $k_a k_b P$.

ECDH protocol (informal):
- The peers agree on a curve and a base point $P\in E(\mathbb{F}_p)$ (with known order r).
- Alice picks a private scalar $k_a\in\{1,\dots,r-1\}$ and sends the public point $A=k_aP$ to Bob.
- Bob picks $k_b$ and sends $B=k_bP$ to Alice.
- Alice computes $S_A=k_a B = k_a(k_bP)=k_a k_b P$.
- Bob computes $S_B=k_b A = k_b(k_aP)=k_b k_a P$.
Both obtain the same shared point $S=k_a k_b P$.

Please play the toy example and watch the key exchange animation on [curves.xargs.org](https://curves.xargs.org/#key-exchange)

Why an eavesdropper cannot recover the shared key (informal):
- If an attacker sees only $A=k_aP$ and $B=k_bP$, then computing $k_a$ or $k_b$ from $A$ or $B$ alone requires solving the ECDLP; computing $k_a k_b P$ directly from $A$ and $B$ without either scalar requires solving the CDH problem. Both problems are believed to be computationally infeasible for well-chosen curves and sufficiently large parameters (e.g., 256-bit prime fields such as Curve25519). Thus knowledge of $A$ and $B$ does not reveal $k_a$ or $k_b$, nor the derived symmetric key, under standard assumptions.

The toy curve Curve61 used $\mathbb{F_{61}}$. In practice, cryptographic curves use much larger prime fields (e.g., Curve25519 uses a 255-bit prime, i.e., $\mathbb{F}_{2^{255}-19}$) to ensure security against known attacks.

## References and further reading

- [The Animated Elliptic Curve](https://curves.xargs.org)
- [Hands-on: X25519 Key Exchange](https://x25519.xargs.org/)

