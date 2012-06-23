request = require("request")
querystring = require("querystring")
_ = require("underscore")

GitHub = 
    getUrl: "https://github.com/login/oauth/authorize"
    tokenUrl: "https://github.com/login/oauth/access_token"
    apiUrl: "https://api.github.com/"
    client_id: process.env.GIT_CLIENT
    client_secret: process.env.GIT_SECRET
    redirect_uri: ''
    scope: 'repo'
    authenticate: (req, res, authenticated) ->
        if req.query.code?
            @getToken req.query.code, (token) ->
                if token?
                    req.session.github = token
                    authenticated(true)
        else
            authenticated(false)
            @initialGet(res)

    initialGet: (res) ->
        redirect = querystring.stringify
            client_id: @client_id
            scope: @scope

        res.redirect("#{@getUrl}?#{redirect}")

    getToken: (tempcode, onToken) ->
        tokenData = 
            url: @tokenUrl
            form:
                client_id: @client_id
                client_secret: @client_secret
                code: tempcode
            method: "POST"

        request tokenData, (e, r, b) ->
            response = querystring.parse(b)
            onToken(response.access_token)

    getWatched: (key, onComplete) ->
        request {
            url: "#{@apiUrl}user/watched?per_page=100"
            headers: {"Authorization": "token #{key}"}
        }, (e, r, b) ->
            data = JSON.parse(b)
            repos = []
            _.each data, (repo) ->
                repos.push
                    id: repo.id
                    url: repo.html_url
                    apiurl: repo.url
                    git_url: repo.git_url
                    owner: repo.owner
                    ownername: repo.owner.login
                    name: repo.name
                    description: repo.description
                    homepage: repo.homepage
                    language: repo.language
                    watchers: repo.watchers
            onComplete(repos)

    removeWatched: (key, author, title, onComplete) ->
        request {
            url: "#{@apiUrl}user/watched/#{author}/#{title}"
            headers: {"Authorization": "token #{key}"}
            method: "DELETE"
        }, (e, r, b) -> onComplete()

module.exports = (app) ->
    app.get '/', (req, res) ->
        connected = req.session.github?
        res.render 'index', {jsvars: {connected: connected}}

    app.get "/repos", (req, res) ->
        GitHub.getWatched req.session.github, (data) -> 
            cachedrepos = data
            res.send(data)

    app.delete "/repos/:author/:title", (req, res) ->
        GitHub.removeWatched req.session.github, req.params.author, req.params.title, ->
        res.send({returntype: "success"})


    app.get '/login', (req, res) ->
        GitHub.authenticate req, res, (auth) -> res.redirect("/") if auth