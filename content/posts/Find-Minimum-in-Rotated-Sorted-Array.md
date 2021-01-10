+++
title = "Find-Minimum-in-Rotated-Sorted-Array"
date = 2019-01-31

[taxonomies]
categories = ["Practice"]
tags = ["problem", "python"]

[extra]
toc = true
+++

# [Find Minimum in Rotated Sorted Array (#153)](https://leetcode.com/problems/find-minimum-in-rotated-sorted-array/)

## Description

Suppose an array sorted in ascending order is rotated at some pivot unknown to you beforehand.
(i.e.,  `[0,1,2,4,5,6,7]` might become  `[4,5,6,7,0,1,2]`).
Find the minimum element.
You may assume no duplicate exists in the array.

---

## Example

### Example 1

```
Input: [3, 4, 5, 1, 2]
Output: 1
```

### Example 2

```
Input: [4, 5, 6, 7, 0, 1, 2]
Output: 0
```

---

<!--more-->

## Solution

### Solution I ([Reference](https://leetcode.com/articles/find-minimum-in-rotated-sorted-array/))

#### Observation

If the sorted array is not rotated, the last element ***always*** larger than first element.

```
[2, 3, 4, 5, 6, 7]
 ^              ^
```

However, if the sorted array is rotated, we want to find the `Infection Point` (i.e. the point whose left element is maximum and right element is minimum).
```
[4, 5, 6, 7, 2, 3]
           ^
```

Furthermore,

- All the elements to the left of inflection point > first element of the array.
- All the elements to the right of inflection point < first element of the array.

---

#### Algorithm

![](https://i.imgur.com/goTfIbm.png)


```
[5, 1, 2, 4, 5]
 l     m     r
 <-----

[5, 1, 2, 4, 5]
 l  r
 m
```

```
[4, 5, 6, 7, 2, 3]
 l     m        r
         ------->

[4, 5, 6, 7, 2, 3]
          l  m  r
```

<p>
Time Complexity:\(O(log\,n)\),
Space Complexity:\(O(1)\)
</p>
---

#### Code

```python
class Solution:
    def findMin(self, nums):
        """
        :type nums: List[int]
        :rtype: int
        """

        if len(nums) == 1:
            return nums[0]


        l, h = 0, len(nums) - 1

        if nums[h] > nums[l]:
            return nums[l]

        while l <= h:
            m = l + (h - l) // 2
            if nums[m] > nums[m + 1]:
                return nums[m + 1]
            if nums[m - 1] > nums[m]:
                return nums[m]

            if nums[m] > nums[0]:
                l = m + 1
            else:
                h = m - 1
```
