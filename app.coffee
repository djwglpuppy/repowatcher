devport = 9100
express = require("express")
RedisStore = require('connect-redis')(express)


app = express.createServer(
    express.bodyParser(),
    express.cookieParser(),
    express.session({secret: "thisisnotthesecretyouarelookingfor",  store: new RedisStore({db: "repowatcher"})})
)

console.log process.env

app.configure ->
    @set('views', __dirname + '/views')
    @set('view engine', 'jade')

app.configure "development", ->

    @use(require("coffee-middle")({
        src: __dirname + "/precompiled/js"
        dest: __dirname + "/static/js"
    }))


    @use(require("stylus").middleware({
        src: __dirname + "/precompiled"
        dest: __dirname + "/static"
        compress: true
    }))

    @use(express.static(__dirname + '/static'))
    @use(this.router)

app.configure 'production', ->
    oneYear = 31557600000
    @use(express.static(__dirname + '/static', { maxAge: oneYear }))
    @use(express.errorHandler())
    @use(this.router)

require("./routes")(app)

if app.settings.env is "development"
    app.listen(devport)
    console.log "Started on port #{devport} in Development Mode"
else
    app.listen(8997)
    console.log "Started on port 8997 in Production Mode"