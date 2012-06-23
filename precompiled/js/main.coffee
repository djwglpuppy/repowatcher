class Repo extends Backbone.Model
	url: -> "/repos/#{@get("ownername")}/#{@get("name")}"

class Repositories extends Backbone.Collection
	model: Repo
	url: "/repos"
	comparator: (repo) ->
		language = repo.get("language")
		if language?
			repo.get("language").toLowerCase()
		else
			repo.set("language", "Unknown")
			"zzzzz"

class Main extends Backbone.View
	filterinit: true
	groupcontainer: null
	el: "body"

	repoLines: (repos) ->
		repos = _.sortBy repos, (repo) -> repo.get("name").toLowerCase()
		_.each repos, (repo) =>

			watched = $(@watch_tpl
				title: repo.get("name")
				watchers: repo.get("watchers")
				description: repo.get("description")
				url: repo.get("url")
				author: repo.get("ownername")
				homeurl: repo.get("homepage")
				git_path: repo.get("git_url")
			)
			gc = @groupcontainer.append(watched)

			watched.find(".remove").click -> watched.find(".removeconfirm").fadeIn(200)
			watched.find(".cancelbtn").click -> watched.find(".removeconfirm").fadeOut(200)
			watched.find(".confirmbtn").click => 
				watched.slideUp 200, =>
					repo.destroy()
					watched.remove()
					if gc.find(".watched-item").length is 0
						$("[data-group='" + gc.attr("data-group") + "']").slideUp 200, -> $(@).remove()

	groupedRepos: (groupby = "language") ->
		grouped = @repos.groupBy (repo) -> repo.get(groupby)
		@filterlist.append("<li><a>ALL <i class='icon-ok'></i></a></li>") if @filterinit

		_.each grouped, (repos, parent) =>
			@filterlist.append("<li><a>#{parent}</a></li>") if @filterinit
			@container.append("<h2 data-group='#{parent}'>#{parent}</h2>")
			@groupcontainer = $(@make("div", {class: "groupcontainer", 'data-group': parent}))
			@container.append @groupcontainer
			@repoLines(repos)
		@filterinit = false
		$("#loader").fadeOut 400, =>
			$("#watched").fadeIn(600)
			$(".maindropdown").show()
			@spinner.stop()

	filterAction: (e) ->
		target = $(e.target)
		forlanguage = target.text()
		if forlanguage in ["", "ALL "]
			forlanguage = "ALL"
			@$el.find("[data-group]").fadeIn(300)
		else	
			@$el.find("[data-group][data-group!='#{forlanguage}']").hide()
			$(".filtertitle b").html(forlanguage)
			@$el.find("[data-group='#{forlanguage}']").fadeIn(300)

		$(".filtertitle b").html(forlanguage)
		@filterlist.find("a i").remove()
		target.append("<i class='icon-ok'></i>")

	events: {"click #filterlist a": "filterAction"}

	spinnerStart: ->
		$("#loader").show()
		opts = 
			lines: 13
			length: 7
			width: 4
			radius: 24
			rotate: 0
			color: '#000'
			speed: 0.9
			trail: 60
			shadow: true
			hwaccel: false
			className: 'spinner'
			zIndex: 2e9
			top: 'auto'
			left: 'auto'
		@spinner = new Spinner(opts).spin($("#spinner")[0])

	start: ->
		@container = @$el.find("#watched")
		@filterlist = @$el.find("#filterlist")
		@watch_tpl = _.template($("#watched-template").text());
		@repos = new Repositories
		@repos.on "reset", => @groupedRepos()
		@spinnerStart()
		@repos.fetch()

$ ->
	$(".maindropdown").hide()
	if _GLOBALS.connected
		main = new Main
		main.start()
		$('.dropdown-toggle').dropdown()
	else
		$("#login").show()
		$("#login .btn").click -> location.href = '/login'