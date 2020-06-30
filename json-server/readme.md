# Testing Static Server

You can create a test server to mock API calls that aren't completed yet using
json-server:

```
npm install -g json-server
```

Start with the `db.json` file in this directory, and add custom routes in
`routes.json`. To start the server, use this command:

```
$ json-server db.json --routes routes.json --static ./public
```

You should now be able to download the agent itself that's under public/ by
visiting localhost:3000/agent. You can get metadata about the agent at
http://localhost:3000/api/v1/minion.

Read up on [json-server](https://github.com/typicode/json-server) for more
information.