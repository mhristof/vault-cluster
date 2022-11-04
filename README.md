# vault cluster

Bring up a docker compose vault cluster


## Help

Use the `make` command to execute commands on the cluster

```
$ make help
help         Show this help.
init         vault init
join         raft join commands to all nodes
list-peers   watch the list-peers output
re           Recreate the env (clean and up)
sh           spawn a shell to vault cluster
shclient     spawn a shell in the client 
status       execute 'vault status' in all nodes
step-down    step down current leader
stress       stress test vault by creating tokens
unseal       vault unseal all nodes
```
