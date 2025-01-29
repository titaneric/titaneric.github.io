+++
title = "Updating-a-Dictionary"
date = 2019-02-17

[taxonomies]
categories = ["Practice"]
tags = ["problem", "c++"]

[extra]
toc = true
+++


# [Updating a Dictionary](https://uva.onlinejudge.org/index.php?option=com_onlinejudge&Itemid=8&page=show_problem&problem=3948)

## Solution

1. Use the regex to parse key, value.
2. Save the parsed keys, values to real map.
3. Compare two maps.
    1. Use the overloading = operator to compare if two maps have no difference.
    2. The intersection between current map's keys and previous map's keys is possible the edit one or equal one.
    3. The difference between current map and intersection mentioned at 3.2 is the new one.
    4. The difference between previous map and intersection mentioned at 3.2 is the delete one.
    5. At last, filter the keys that corresponding value of current map and previous map are not the same. That is the edit one.

## What I learn

1. Use the regex lib at C++ for the first time.
2. Practice the C++ 11. E.g., copy_if, lambda.

## Code
```c++
#include <iostream>
#include <map>
#include <algorithm>
#include <string>
#include <regex>
#include <vector>
#include <set>
#include <iterator>

using namespace std;

regex key_regex("([a-z]+)");
regex value_regex("([0-9]+)");

void parse2Dict(string &line, map<string, string> &dict)
{
    auto key_begin = sregex_iterator(line.begin(), line.end(), key_regex);
    auto key_end = sregex_iterator();

    auto value_begin = sregex_iterator(line.begin(), line.end(), value_regex);
    auto value_end = sregex_iterator();
    for (auto k = key_begin, v = value_begin; k != key_end && v != value_end; ++k, ++v)
    {
        dict[k->str()] = v->str();
    }
}
void output(char op, set<string> &target)
{
    vector<string> target_vec(target.begin(), target.end());
    cout << op;
    for (auto k : target_vec)
    {
        cout << k;
        if (k != target_vec.back())
            cout << ",";
    }
    cout << endl;
}
void compareDict(map<string, string> &previous, map<string, string> &current)
{
    if (previous == current)
    {
        printf("No changes\n");
    }
    else
    {
        set<string> previous_key;
        for (auto iter : previous)
        {
            previous_key.insert(iter.first);
        }

        set<string> current_key;
        for (auto iter : current)
        {
            current_key.insert(iter.first);
        }

        // *
        set<string> possible_star;
        set_intersection(current_key.begin(), current_key.end(), previous_key.begin(), previous_key.end(), inserter(possible_star, possible_star.begin()));

        // +
        set<string> plus;
        set_difference(current_key.begin(), current_key.end(), possible_star.begin(), possible_star.end(), inserter(plus, plus.begin()));
        if (plus.size())
            output('+', plus);

        // -
        set<string> minus;
        set_difference(previous_key.begin(), previous_key.end(), possible_star.begin(), possible_star.end(), inserter(minus, minus.begin()));
        if (minus.size())
            output('-', minus);

        // *
        set<string> star;
        copy_if(possible_star.begin(), possible_star.end(), inserter(star, star.begin()), [&](string k) { return current[k] != previous[k]; });
        if (star.size())
            output('*', star);
    }
}
int main()
{
    int n;
    string line;
    scanf("%d", &n);
    getline(cin, line);

    for (int i = 0; i < n; i++)
    {
        getline(cin, line);
        map<string, string> previous_map;
        parse2Dict(line, previous_map);

        getline(cin, line);
        map<string, string> current_map;
        parse2Dict(line, current_map);

        compareDict(previous_map, current_map);
        cout << endl;
    }

    return 0;
}
```
