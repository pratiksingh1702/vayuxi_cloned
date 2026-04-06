# ShimmerList — Complete Guide

> A plug-and-play shimmer loading widget for Flutter.  
> Works anywhere. Looks great. Zero configuration required.

---

## Table of Contents

1. [What is a Shimmer?](#1-what-is-a-shimmer)
2. [Setup & Installation](#2-setup--installation)
3. [Quick Start — 30 Seconds to Working Shimmer](#3-quick-start--30-seconds-to-working-shimmer)
4. [Understanding the 4 Built-in Types](#4-understanding-the-4-built-in-types)
5. [All Parameters Explained](#5-all-parameters-explained)
6. [Real-World Use Cases with Full Code](#6-real-world-use-cases-with-full-code)
   - [News / Blog Feed](#61-news--blog-feed)
   - [Contacts / Chat List](#62-contacts--chat-list)
   - [Social / Followers List](#63-social--followers-list)
   - [E-commerce Product Grid](#64-e-commerce-product-grid)
   - [Inside a Tab View](#65-inside-a-tab-view)
   - [Mixed Screen (Header + List)](#66-mixed-screen-header--list)
   - [Pull-to-Refresh Pattern](#67-pull-to-refresh-pattern)
   - [FutureBuilder Pattern](#68-futurebuilder-pattern)
   - [StreamBuilder Pattern](#69-streambuilder-pattern)
   - [Custom Item Shape](#610-custom-item-shape)
   - [Dark Mode](#611-dark-mode)
   - [Branded / Themed Colors](#612-branded--themed-colors)
7. [The `scrollable` Parameter — When to Use It](#7-the-scrollable-parameter--when-to-use-it)
8. [Building Custom Shimmer Items from Scratch](#8-building-custom-shimmer-items-from-scratch)
9. [Common Mistakes & How to Avoid Them](#9-common-mistakes--how-to-avoid-them)
10. [Quick Reference Cheatsheet](#10-quick-reference-cheatsheet)

---

## 1. What is a Shimmer?

A **shimmer** is the animated grey-wave effect you see on apps like Facebook, YouTube, and LinkedIn while content is loading. Instead of showing a spinner, you show a skeleton that looks like the real content — users instantly understand "data is coming."

```
Without shimmer:           With shimmer:
┌──────────────┐           ┌──────────────┐
│  ⟳ Loading…  │           │ ▓▓▓▓▓▓▓▓▓▓▓ │  ← looks like a card
└──────────────┘           │ ▒▒▒▒▒▒       │
                           │ ▒▒▒▒         │
                           └──────────────┘
```

`ShimmerList` handles all the shimmer logic for you. You just drop it in and swap it out when data arrives.

---

## 2. Setup & Installation

### Step 1 — Add the shimmer package

In your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  shimmer: ^3.0.0   # or latest version
```

Then run:

```bash
flutter pub get
```

### Step 2 — Add the file

Copy `shimmer_list.dart` into your project, for example:

```
lib/
  widgets/
    shimmer_list.dart   ← paste it here
```

### Step 3 — Import it wherever you need it

```dart
import 'package:your_app/widgets/shimmer_list.dart';
```

That's it. No further configuration needed.

---

## 3. Quick Start — 30 Seconds to Working Shimmer

Here is the absolute minimum code to get a shimmer loading screen:

```dart
import 'package:flutter/material.dart';
import 'package:your_app/widgets/shimmer_list.dart';

class MyScreen extends StatelessWidget {
  final bool isLoading = true; // pretend data is loading

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ShimmerList(); // ← done. shimmer appears.
    }

    return ListView(
      children: [Text('Real content here')],
    );
  }
}
```

**Result:** 6 animated shimmer cards, light mode colors, scrollable.

---

## 4. Understanding the 4 Built-in Types

Pass the `type` parameter to choose the layout that matches your real content.

### `ShimmerListType.card` *(default)*

Best for: blog posts, news articles, product listings with a large image.

```
┌────────────────────────┐
│                        │  ← image placeholder (160px tall)
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│                        │
├────────────────────────┤
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ │  ← title line
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒         │  ← subtitle line
│ ▒▒▒▒▒▒▒▒               │  ← meta line
└────────────────────────┘
```

```dart
ShimmerList(type: ShimmerListType.card)
```

---

### `ShimmerListType.tile`

Best for: contact lists, chat lists, notification lists, anything like Flutter's `ListTile`.

```
┌────────────────────────────────────┐
│  ●   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   ▒▒▒▒   │
│      ▒▒▒▒▒▒▒▒▒▒▒                  │
└────────────────────────────────────┘
  ↑ circle avatar    ↑ two text lines   ↑ trailing text
```

```dart
ShimmerList(type: ShimmerListType.tile)
```

---

### `ShimmerListType.avatar`

Best for: social profiles, followers/following lists, team members, user directories.

```
┌─────────────────────────────────────────┐
│   ◉    ▒▒▒▒▒▒▒▒▒▒                      │
│        ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒       │
│        ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒               │
└─────────────────────────────────────────┘
  ↑ larger circle     ↑ name + 2 description lines
```

```dart
ShimmerList(type: ShimmerListType.avatar)
```

---

### `ShimmerListType.grid`

Best for: product grids, photo galleries, category tiles.

```
┌───────────┐  ┌───────────┐
│           │  │           │  ← image area
│  ▓▓▓▓▓▓  │  │  ▓▓▓▓▓▓  │
│           │  │           │
│ ▒▒▒▒▒▒▒▒ │  │ ▒▒▒▒▒▒▒▒ │  ← title
│ ▒▒▒▒     │  │ ▒▒▒▒     │  ← price / tag
└───────────┘  └───────────┘
```

```dart
ShimmerList(
  type: ShimmerListType.grid,
  crossAxisCount: 2,
)
```

---

## 5. All Parameters Explained

```dart
ShimmerList({
  int itemCount = 6,
  ShimmerListType type = ShimmerListType.card,
  Color? baseColor,
  Color? highlightColor,
  EdgeInsetsGeometry padding = EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  double itemSpacing = 12,
  bool scrollable = true,
  int crossAxisCount = 2,        // grid only
  double gridChildAspectRatio = 1.0,  // grid only
})
```

| Parameter | Type | Default | What it does |
|---|---|---|---|
| `itemCount` | `int` | `6` | How many shimmer items to show |
| `type` | `ShimmerListType` | `.card` | Which shimmer layout to use |
| `baseColor` | `Color?` | auto | The "base" grey color of the shimmer |
| `highlightColor` | `Color?` | auto | The "shine" color that sweeps across |
| `padding` | `EdgeInsetsGeometry` | H:16, V:12 | Outer padding around the whole list |
| `itemSpacing` | `double` | `12` | Gap between each shimmer item |
| `scrollable` | `bool` | `true` | Set `false` when inside a `ListView` or `Column` |
| `crossAxisCount` | `int` | `2` | Grid columns (grid type only) |
| `gridChildAspectRatio` | `double` | `1.0` | Grid item width÷height ratio (grid type only) |

### Color defaults (automatic)

You don't need to set colors. The widget detects light/dark mode automatically:

| Mode | `baseColor` | `highlightColor` |
|---|---|---|
| Light | `#E0E0E0` (grey) | `#F5F5F5` (near-white) |
| Dark | `#2A2A2A` (dark grey) | `#3A3A3A` (lighter dark) |

---

## 6. Real-World Use Cases with Full Code

### 6.1 News / Blog Feed

A screen that loads articles from an API. Show card shimmer while waiting.

```dart
class NewsScreen extends StatefulWidget {
  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _isLoading = true;
  List<Article> _articles = [];

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    // Simulate an API call
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _articles = fetchedArticles; // your real data
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('News')),
      body: _isLoading
          ? ShimmerList(
              itemCount: 5,
              type: ShimmerListType.card,
            )
          : ListView.builder(
              itemCount: _articles.length,
              itemBuilder: (ctx, i) => ArticleCard(_articles[i]),
            ),
    );
  }
}
```

---

### 6.2 Contacts / Chat List

A contacts screen or messaging inbox. Use tile shimmer — it mimics `ListTile` perfectly.

```dart
class ContactsScreen extends StatelessWidget {
  final bool isLoading;
  final List<Contact> contacts;

  const ContactsScreen({
    required this.isLoading,
    required this.contacts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: isLoading
          ? ShimmerList(
              type: ShimmerListType.tile,
              itemCount: 8,        // show 8 placeholder rows
              itemSpacing: 8,      // tighter spacing for tiles
            )
          : ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (ctx, i) => ContactTile(contacts[i]),
            ),
    );
  }
}
```

---

### 6.3 Social / Followers List

A "followers" or "following" screen. Use the avatar type.

```dart
class FollowersScreen extends StatefulWidget {
  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  bool _loading = true;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    final users = await api.getFollowers();
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Followers')),
      body: _loading
          ? ShimmerList(
              type: ShimmerListType.avatar,
              itemCount: 10,
            )
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (ctx, i) => UserRow(_users[i]),
            ),
    );
  }
}
```

---

### 6.4 E-commerce Product Grid

A shop screen with a 2-column product grid.

```dart
class ShopScreen extends StatelessWidget {
  final bool isLoading;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: isLoading
          ? ShimmerList(
              type: ShimmerListType.grid,
              itemCount: 6,              // 6 items = 3 rows of 2
              crossAxisCount: 2,
              gridChildAspectRatio: 0.75, // taller than wide (portrait product card)
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
              ),
              itemCount: products.length,
              itemBuilder: (ctx, i) => ProductCard(products[i]),
            ),
    );
  }
}
```

**Tip on `gridChildAspectRatio`:**
- `1.0` = square items
- `0.75` = taller than wide (portrait, good for products)
- `1.5` = wider than tall (landscape, good for video thumbnails)

---

### 6.5 Inside a Tab View

When you have tabs with a loading state per tab. Use `scrollable: false` to avoid scroll conflicts.

```dart
class HomeTabsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [Tab(text: 'Feed'), Tab(text: 'Popular'), Tab(text: 'Saved')],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: loading
            ShimmerList(
              type: ShimmerListType.card,
              itemCount: 4,
              scrollable: false, // ← IMPORTANT inside TabBarView
            ),

            // Tab 2: real content
            ListView(children: [Text('Popular content')]),

            // Tab 3: empty
            const Center(child: Text('Nothing saved yet')),
          ],
        ),
      ),
    );
  }
}
```

---

### 6.6 Mixed Screen (Header + List)

A screen with a non-shimmer header and a shimmer list below — everything in one `ListView`.

```dart
class ProfileScreen extends StatelessWidget {
  final bool isPostsLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // Real header — always visible
          ProfileHeader(),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Posts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          // Shimmer only for the posts section
          if (isPostsLoading)
            ShimmerList(
              type: ShimmerListType.card,
              itemCount: 3,
              scrollable: false,  // ← inside a ListView, MUST be false
              padding: const EdgeInsets.symmetric(horizontal: 16),
            )
          else
            PostsList(),
        ],
      ),
    );
  }
}
```

> ⚠️ **Key rule:** Whenever `ShimmerList` is placed inside another scrollable widget (`ListView`, `SingleChildScrollView`, `CustomScrollView`), always set `scrollable: false`.

---

### 6.7 Pull-to-Refresh Pattern

Show shimmer during initial load, but keep real content during refresh.

```dart
class FeedScreen extends StatefulWidget {
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _initialLoading = true;
  bool _refreshing = false;
  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final posts = await api.getPosts();
    setState(() {
      _posts = posts;
      _initialLoading = false;
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    final posts = await api.getPosts();
    setState(() {
      _posts = posts;
      _refreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show full shimmer only on first load
    if (_initialLoading) {
      return ShimmerList(type: ShimmerListType.card, itemCount: 5);
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (ctx, i) => PostCard(_posts[i]),
      ),
    );
    // During refresh, the RefreshIndicator spinner shows — no shimmer needed
  }
}
```

---

### 6.8 FutureBuilder Pattern

If you use `FutureBuilder` to fetch data, integrate shimmer in the loading state:

```dart
class ArticleListScreen extends StatelessWidget {
  final Future<List<Article>> articlesFuture = ArticleService.fetch();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Articles')),
      body: FutureBuilder<List<Article>>(
        future: articlesFuture,
        builder: (context, snapshot) {
          // ── Loading state ──
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ShimmerList(
              type: ShimmerListType.card,
              itemCount: 5,
            );
          }

          // ── Error state ──
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // ── Success state ──
          final articles = snapshot.data!;
          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (ctx, i) => ArticleCard(articles[i]),
          );
        },
      ),
    );
  }
}
```

---

### 6.9 StreamBuilder Pattern

For real-time data (Firestore, WebSocket, etc.):

```dart
class LiveFeedScreen extends StatelessWidget {
  final Stream<List<Post>> postsStream = FirestoreService.postsStream();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: postsStream,
      builder: (context, snapshot) {
        // First emission hasn't arrived yet
        if (!snapshot.hasData) {
          return ShimmerList(
            type: ShimmerListType.tile,
            itemCount: 6,
          );
        }

        final posts = snapshot.data!;

        if (posts.isEmpty) {
          return const Center(child: Text('No posts yet'));
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (ctx, i) => PostTile(posts[i]),
        );
      },
    );
  }
}
```

---

### 6.10 Custom Item Shape

When none of the 4 built-in types match your real UI, build your own item using `ShimmerList.custom()`.

**Example: A transaction row (icon + amount + date)**

```dart
// First, define your custom shimmer item widget
class _TransactionShimmerItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Icon placeholder (square rounded)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          // Text lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 120, height: 13, color: Colors.white),
                const SizedBox(height: 6),
                Container(width: 80, height: 11, color: Colors.white),
              ],
            ),
          ),
          // Amount on the right
          Container(width: 60, height: 14, color: Colors.white),
        ],
      ),
    );
  }
}

// Then use it with ShimmerList.custom()
class TransactionsScreen extends StatelessWidget {
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: isLoading
          ? ShimmerList.custom(
              itemCount: 7,
              itemBuilder: (context, index) => _TransactionShimmerItem(),
            )
          : _buildTransactionList(),
    );
  }
}
```

**Example: A story/reel strip (horizontal circles at the top)**

```dart
// Horizontal shimmer row — wrap in a SizedBox with fixed height
SizedBox(
  height: 90,
  child: ShimmerList.custom(
    itemCount: 6,
    scrollable: false,
    itemBuilder: (context, index) => Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 6),
          Container(width: 50, height: 10, color: Colors.white),
        ],
      ),
    ),
  ),
),
```

---

### 6.11 Dark Mode

Dark mode colors are handled **automatically** — the widget reads `Theme.of(context).brightness`.

```dart
// This works perfectly in both light AND dark mode — no extra code needed:
ShimmerList(type: ShimmerListType.tile)
```

To force a specific mode regardless of system theme:

```dart
ShimmerList(
  type: ShimmerListType.card,
  baseColor: const Color(0xFF1E1E1E),      // force dark base
  highlightColor: const Color(0xFF2C2C2C), // force dark highlight
)
```

---

### 6.12 Branded / Themed Colors

Match your app's brand color for a premium feel.

```dart
// Blue-tinted shimmer (e.g., a banking app)
ShimmerList(
  type: ShimmerListType.tile,
  baseColor: const Color(0xFFDDE8F5),
  highlightColor: const Color(0xFFEEF4FB),
)

// Warm amber shimmer (e.g., a food delivery app)
ShimmerList(
  type: ShimmerListType.card,
  baseColor: const Color(0xFFF5E9D0),
  highlightColor: const Color(0xFFFAF3E6),
)

// Green-tinted shimmer (e.g., a finance/investment app)
ShimmerList(
  type: ShimmerListType.tile,
  baseColor: const Color(0xFFD4EAD8),
  highlightColor: const Color(0xFFE8F5EA),
)
```

---

## 7. The `scrollable` Parameter — When to Use It

This is the most common source of confusion for beginners. Here's the simple rule:

### Use `scrollable: true` (default) when:

`ShimmerList` **is** the main scrollable content of the screen.

```dart
// ✅ Correct — ShimmerList fills the screen
Scaffold(
  body: ShimmerList(type: ShimmerListType.card),
)
```

### Use `scrollable: false` when:

`ShimmerList` is **inside** another scrollable widget.

```dart
// ✅ Correct — ShimmerList is a child inside ListView
ListView(
  children: [
    SomeHeader(),
    ShimmerList(
      scrollable: false,  // ← REQUIRED here
      itemCount: 4,
    ),
  ],
)

// ✅ Correct — inside Column inside SingleChildScrollView
SingleChildScrollView(
  child: Column(
    children: [
      ProfileBanner(),
      ShimmerList(
        scrollable: false,  // ← REQUIRED here
      ),
    ],
  ),
)

// ✅ Correct — inside TabBarView
TabBarView(
  children: [
    ShimmerList(scrollable: false), // ← REQUIRED here
    RealContent(),
  ],
)
```

### What happens if you forget `scrollable: false`?

You'll get a Flutter error like:
```
Vertical viewport was given unbounded height.
```

If you ever see this error after placing `ShimmerList`, add `scrollable: false` and it will be fixed.

---

## 8. Building Custom Shimmer Items from Scratch

When you use `ShimmerList.custom()`, your `itemBuilder` widget needs to follow one rule:

> **Use `Colors.white` as the color for every placeholder box/circle.**

The `Shimmer.fromColors` wrapper handles all the animation. It replaces white with the animated grey-to-light sweep. If you use any other color, the shimmer won't apply to that element.

### Template for a custom shimmer item:

```dart
class MyCustomShimmerItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      // Outer card
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,          // ← always white
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Circle placeholder
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.white,    // ← always white
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line placeholder (full width)
                Container(
                  height: 14,
                  color: Colors.white,  // ← always white
                ),
                const SizedBox(height: 8),
                // Line placeholder (partial width)
                Container(
                  width: 100,
                  height: 12,
                  color: Colors.white,  // ← always white
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Matching your shimmer item to your real item

The best shimmer item mimics the **shape and proportion** of your real content.

```
Real ListTile:                  Shimmer version:
┌──────────────────────────┐    ┌──────────────────────────┐
│ 🖼 John Doe              │    │ ●  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒        │
│    Software Engineer     │    │    ▒▒▒▒▒▒▒▒▒▒            │
└──────────────────────────┘    └──────────────────────────┘
  photo  name + role              circle  two lines
```

Match:
- Circle size → avatar size
- Line widths → approximate text widths
- Line heights → approximate font sizes (title ≈ 14px, subtitle ≈ 12px)

---

## 9. Common Mistakes & How to Avoid Them

### ❌ Mistake 1: Forgetting `scrollable: false` inside a ListView

```dart
// ❌ This crashes with "unbounded height" error
ListView(
  children: [
    ShimmerList(), // missing scrollable: false
  ],
)

// ✅ Fix
ListView(
  children: [
    ShimmerList(scrollable: false),
  ],
)
```

---

### ❌ Mistake 2: Using non-white colors in custom item builders

```dart
// ❌ This box won't shimmer — it stays grey
Container(
  width: 100,
  height: 14,
  color: Colors.grey[300], // wrong!
)

// ✅ Fix — always use white inside shimmer items
Container(
  width: 100,
  height: 14,
  color: Colors.white, // correct
)
```

---

### ❌ Mistake 3: Showing shimmer after data loads

```dart
// ❌ Shimmer stays visible even after loading finishes
body: ShimmerList() // always shown

// ✅ Fix — use a condition
body: isLoading
    ? ShimmerList()
    : MyRealListWidget()
```

---

### ❌ Mistake 4: Wrong `gridChildAspectRatio` on grid

```dart
// ❌ Items look squished/stretched
ShimmerList(
  type: ShimmerListType.grid,
  gridChildAspectRatio: 1.0, // wrong for portrait product cards
)

// ✅ Fix — use 0.75 for portrait, 1.3 for landscape
ShimmerList(
  type: ShimmerListType.grid,
  gridChildAspectRatio: 0.75,
)
```

---

### ❌ Mistake 5: Too many shimmer items

```dart
// ❌ 50 items is excessive and wastes memory
ShimmerList(itemCount: 50)

// ✅ Fix — show only as many as fit on screen (5–8 is usually enough)
ShimmerList(itemCount: 6)
```

---

### ❌ Mistake 6: Not matching shimmer type to real content

```dart
// ❌ You show card shimmer but real content is tiles
// Users see a layout shift when data loads — confusing

isLoading
  ? ShimmerList(type: ShimmerListType.card)  // wrong type!
  : ListView.builder(
      itemBuilder: (ctx, i) => ListTile(...), // tile layout
    )

// ✅ Fix — match the shimmer type to the real content type
isLoading
  ? ShimmerList(type: ShimmerListType.tile)  // matches!
  : ListView.builder(
      itemBuilder: (ctx, i) => ListTile(...),
    )
```

---

## 10. Quick Reference Cheatsheet

```dart
// ── Basic Usage ──────────────────────────────────────────────
ShimmerList()                          // 6 cards, light mode, scrollable
ShimmerList(itemCount: 4)              // 4 cards
ShimmerList(type: ShimmerListType.tile)   // tile layout
ShimmerList(type: ShimmerListType.avatar) // avatar layout
ShimmerList(type: ShimmerListType.grid)   // 2-column grid

// ── Inside Another Scroll Widget ─────────────────────────────
ShimmerList(scrollable: false)         // use inside ListView/Column

// ── Grid Options ─────────────────────────────────────────────
ShimmerList(
  type: ShimmerListType.grid,
  crossAxisCount: 3,                   // 3 columns
  gridChildAspectRatio: 0.75,          // portrait items
)

// ── Spacing & Padding ─────────────────────────────────────────
ShimmerList(
  itemSpacing: 8,                      // tighter rows
  padding: EdgeInsets.all(24),         // custom outer padding
)

// ── Colors ───────────────────────────────────────────────────
ShimmerList(
  baseColor: Color(0xFFE0E0E0),
  highlightColor: Color(0xFFF5F5F5),
)

// ── Custom Item Builder ───────────────────────────────────────
ShimmerList.custom(
  itemCount: 5,
  itemBuilder: (context, index) => MyShimmerItem(),
)

// ── FutureBuilder ─────────────────────────────────────────────
FutureBuilder(
  future: myFuture,
  builder: (ctx, snap) => snap.hasData
      ? RealList(snap.data!)
      : ShimmerList(type: ShimmerListType.tile),
)

// ── StreamBuilder ─────────────────────────────────────────────
StreamBuilder(
  stream: myStream,
  builder: (ctx, snap) => snap.hasData
      ? RealList(snap.data!)
      : ShimmerList(type: ShimmerListType.card),
)
```

---

*Made with ❤️ for Flutter developers. Drop `shimmer_list.dart` into any project and you're done.*