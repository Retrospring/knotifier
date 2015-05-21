require! "js-yaml": \yaml
require! \fs
require! \path
require! \url
require! "commander": \program
require! "../package.json": \pkg

env = do
  ws:
    port: 34569
    hostname: '127.0.0.1'
  redis:
    port: 6379
    hostname: '127.0.0.1'
  justask: path.resolve process.env.RAILS_ROOT || path.resolve __dirname, "../../"
  debug: false
  quiet: false

program
  .version pkg.version
  .option '-d, --debug', 'Run in debug mode'
  .option '-q, --quiet', 'Don\'t output anything'
  .option '--rails <path>', 'Specify rails root'
  .option '--listen <uri>', 'Specify which address to listen to'
  .option '--redis <uri>', 'Specify redis url'
  .parse process.argv

env.quiet = program.quiet?
env.debug = program.debug?

if program.rails?
  env.justask = progarm.rails
env.justask = path.resolve env.justask, 'config', 'justask.yml'

try
  env.justask = yaml.safe-load fs.read-file-sync env.justask, 'utf8'
catch e
  env.justask = {}

REDIS_URI = program.redis or env.justask.redis_url
if REDIS_URI?
  env.redis = url.parse REDIS_URI

WS_URI = program.listen or env.justask.knotifier_url or process.env.KNOTIFIER_URI or process.env.KNOTIFIER_HOST
if WS_URI?
  if WS_URI == process.env.KNOTIFIER_HOST
    WS_URI += ":" + (process.env.KNOTIFIER_PORT or 34569)
  env.ws = url.parse WS_URI

export import env
