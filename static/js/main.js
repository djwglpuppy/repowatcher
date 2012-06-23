var Main, Repo, Repositories,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Repo = (function(_super) {

  __extends(Repo, _super);

  function Repo() {
    return Repo.__super__.constructor.apply(this, arguments);
  }

  Repo.prototype.url = function() {
    return "/repos/" + (this.get("ownername")) + "/" + (this.get("name"));
  };

  return Repo;

})(Backbone.Model);

Repositories = (function(_super) {

  __extends(Repositories, _super);

  function Repositories() {
    return Repositories.__super__.constructor.apply(this, arguments);
  }

  Repositories.prototype.model = Repo;

  Repositories.prototype.url = "/repos";

  Repositories.prototype.comparator = function(repo) {
    var language;
    language = repo.get("language");
    if (language != null) {
      return repo.get("language").toLowerCase();
    } else {
      repo.set("language", "Unknown");
      return "zzzzz";
    }
  };

  return Repositories;

})(Backbone.Collection);

Main = (function(_super) {

  __extends(Main, _super);

  function Main() {
    return Main.__super__.constructor.apply(this, arguments);
  }

  Main.prototype.filterinit = true;

  Main.prototype.groupcontainer = null;

  Main.prototype.el = "body";

  Main.prototype.repoLines = function(repos) {
    var _this = this;
    repos = _.sortBy(repos, function(repo) {
      return repo.get("name").toLowerCase();
    });
    return _.each(repos, function(repo) {
      var gc, watched;
      watched = $(_this.watch_tpl({
        title: repo.get("name"),
        watchers: repo.get("watchers"),
        description: repo.get("description"),
        url: repo.get("url"),
        author: repo.get("ownername"),
        homeurl: repo.get("homepage"),
        git_path: repo.get("git_url")
      }));
      gc = _this.groupcontainer.append(watched);
      watched.find(".remove").click(function() {
        return watched.find(".removeconfirm").fadeIn(200);
      });
      watched.find(".cancelbtn").click(function() {
        return watched.find(".removeconfirm").fadeOut(200);
      });
      return watched.find(".confirmbtn").click(function() {
        return watched.slideUp(200, function() {
          repo.destroy();
          watched.remove();
          if (gc.find(".watched-item").length === 0) {
            return $("[data-group='" + gc.attr("data-group") + "']").slideUp(200, function() {
              return $(this).remove();
            });
          }
        });
      });
    });
  };

  Main.prototype.groupedRepos = function(groupby) {
    var grouped,
      _this = this;
    if (groupby == null) {
      groupby = "language";
    }
    grouped = this.repos.groupBy(function(repo) {
      return repo.get(groupby);
    });
    if (this.filterinit) {
      this.filterlist.append("<li><a>ALL <i class='icon-ok'></i></a></li>");
    }
    _.each(grouped, function(repos, parent) {
      if (_this.filterinit) {
        _this.filterlist.append("<li><a>" + parent + "</a></li>");
      }
      _this.container.append("<h2 data-group='" + parent + "'>" + parent + "</h2>");
      _this.groupcontainer = $(_this.make("div", {
        "class": "groupcontainer",
        'data-group': parent
      }));
      _this.container.append(_this.groupcontainer);
      return _this.repoLines(repos);
    });
    this.filterinit = false;
    return $("#loader").fadeOut(400, function() {
      $("#watched").fadeIn(600);
      $(".maindropdown").show();
      return _this.spinner.stop();
    });
  };

  Main.prototype.filterAction = function(e) {
    var forlanguage, target;
    target = $(e.target);
    forlanguage = target.text();
    if (forlanguage === "" || forlanguage === "ALL ") {
      forlanguage = "ALL";
      this.$el.find("[data-group]").fadeIn(300);
    } else {
      this.$el.find("[data-group][data-group!='" + forlanguage + "']").hide();
      $(".filtertitle b").html(forlanguage);
      this.$el.find("[data-group='" + forlanguage + "']").fadeIn(300);
    }
    $(".filtertitle b").html(forlanguage);
    this.filterlist.find("a i").remove();
    return target.append("<i class='icon-ok'></i>");
  };

  Main.prototype.events = {
    "click #filterlist a": "filterAction"
  };

  Main.prototype.spinnerStart = function() {
    var opts;
    $("#loader").show();
    opts = {
      lines: 13,
      length: 7,
      width: 4,
      radius: 24,
      rotate: 0,
      color: '#000',
      speed: 0.9,
      trail: 60,
      shadow: true,
      hwaccel: false,
      className: 'spinner',
      zIndex: 2e9,
      top: 'auto',
      left: 'auto'
    };
    return this.spinner = new Spinner(opts).spin($("#spinner")[0]);
  };

  Main.prototype.start = function() {
    var _this = this;
    this.container = this.$el.find("#watched");
    this.filterlist = this.$el.find("#filterlist");
    this.watch_tpl = _.template($("#watched-template").text());
    this.repos = new Repositories;
    this.repos.on("reset", function() {
      return _this.groupedRepos();
    });
    this.spinnerStart();
    return this.repos.fetch();
  };

  return Main;

})(Backbone.View);

$(function() {
  var main;
  $(".maindropdown").hide();
  if (_GLOBALS.connected) {
    main = new Main;
    main.start();
    return $('.dropdown-toggle').dropdown();
  } else {
    $("#login").show();
    return $("#login .btn").click(function() {
      return location.href = '/login';
    });
  }
});
