# Minion Agent Client

This is the Crystal version of the Minion Agent Client.

It provides a Crystal Language library to connect to and interact with a Minion Streamserver.

Key features currently:

* Connects to a streamserver
* Basic authentication
* Can send logs
* Sophisticated handling of server failures; messages and logs are queued locally, and spooled back to the server when it reconnects.
* Is generally robust to poor network connections and losing connectivity.
* Interactive Agent REPL Shell to manually send and receive from the stream server.

TODO:

* Add support for TLS encryption of the socket communications.
* Add a real debug option to show all communications.

## Communications Protocol

The payloads are serialized using the MessagePack protocol.  MessagePack does
not serialize the length of the serialized data, which negatively affects
network read performance. To work around this, all data which is sent or
received is prefixed with two bytes which encode the length of the data packet
that follows.

The total size of this two byte header plus the data packet can be no longer
than 8k (8192 bytes).

The two byte length is transfered in Big Endian order.

So, for example, consider the following message:

```
2020-06-10 16:23:50 -06:00|stderr|warn|this is very very serious
```

That is 66 bytes when serialized to MessagePack. Expressed as two bytes, big
endian, that is:

```
00.42
```

Those two bytes should be the first two sent, and then immediately after those
bytes should come the other 66 bytes.

# Agent

Notes for the agent go here.

## To Upgrade

There are two sides to every upgrade: user and developer. The developer side
comes first - here's the checklist for publishing an upgrade.

1. Modify the version number in src/minion/agent/version.cr
1. Modify it again in the API to match
1. Publish the agent binary at the location the API says to find it

From the user's side:

1. Run `CONFIG=/full/path/to/config.yml /opt/minion/bin/minion-agent -u`

This is assuming minion-agent is installed in `/opt` of course.

This will upgrade to the latest version (see config.yml for where it looks for
what the latest version actually _is_) and start the agent.

## Issuing Commands

I was going to throw together a little utility to insert commands, but the manual process:
Create a 'commands' record for the command.
Ensure that there is a 'servers' record for the agent.
Create a 'servers_commands' record that links the command to run with the server to run it on.
Insert the command_id into the 'command_queues' table.
Send the notification signal with `notify agent_commands`
That will run it, and get the response back into the command_responses table. It will update the servers_commands table, as well, with the time that the command was dispatched, and the time that the response was received, as well as the UUID of the