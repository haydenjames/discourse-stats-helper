![discourse-stats-helper screenshot](https://linuxcommunity.io/uploads/default/original/2X/f/f959d2dc21c3d52caa9706eee0ac6c02c244b00a.png)

This is a small helper script built for anyone running, managing, or using a Discourse forum. It provides an interactive menu for quickly retrieving live forum statistics from the `site/statistics.json` endpoint using `curl` and `jq`. 

The script is useful for administrators who want a simple way to check metrics without browsing the admin panel.

The tool supports both interactive and one-off direct queries. It automatically detects all numeric fields returned by the Discourse API, provides short descriptions for common metrics, and gracefully handles fields that may not exist on every forum.

### **Who this is for**

* System administrators
* Self-hosted Discourse operators
* Moderators who occasionally work with analytics
* Anyone who wants a fast command-line way to view Discourse stats

### **What it does**

* Fetches all numeric statistics from `/site/statistics.json`
* Supports single metric lookup (topics, posts, likes, users, etc.)
* Provides an interactive menu for browsing metrics
* Works on any Discourse instance (self-hosted or hosted)
* Handles missing fields cleanly
* Requires only `bash`, `curl`, and `jq`: `apt install curl jq`

---

# **How to use**

### **Download the script**

```
curl -O https://raw.githubusercontent.com/haydenjames/discourse-stats-helper/main/discourse_stats.sh
chmod +x discourse_stats.sh
```

### **Run it against any Discourse forum**

```
./discourse_stats.sh https://your.discourse.site
```

You will be presented with an interactive list of statistics to choose from.
Select a number to view one metric, `a` to list all metrics, `h` for help, or `q` to exit.

### **Example**

```
./discourse_stats.sh https://linuxcommunity.io
```

This will connect to your forum and display its available statistics.

---

# **Repository**

The full source and documentation are available here:
**[https://github.com/haydenjames/discourse-stats-helper](https://github.com/haydenjames/discourse-stats-helper)**

### **More details**  
https://linuxcommunity.io/t/discourse-stats-helper-bash-script/6012
