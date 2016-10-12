# Install Marathon-LB on Mesosphere Enterprise DC/OS

Unlike DC/OS, which only supports authentication, Enterprise DC/OS supports fine grained authorization.

For security reasons, Enterprise DC/OS by default denies access to administrative APIs.

In order to allow Marathon-LB read access to the Marathon service lists, service details, and event stream the following steps must be taken:

```
# install the security cli plugin
$ dcos package install dcos-enterprise-cli

# generate a public/private key pair
$ dcos security org service-accounts keypair marathon-lb-private.pem marathon-lb-public-key.pem

# create a new service account
$ dcos security org service-accounts create -p marathon-lb-public-key.pem marathon-lb

# create a new service account secret
$ dcos security secrets create-sa-secret marathon-lb-private.pem marathon-lb marathon-lb-private-key

# download the DC/OS cluster public key
$ curl -k -v -o dcos-ca.pem http://m1.dcos/ca/dcos-ca.crt

# create new permission groups (marathon services & events)
$ curl -X PUT \
  --cacert dcos-ca.pem \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
  $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F \
  -d '{"description":"Allows access to any service launched by the native Marathon instance"}' \
  -H 'Content-Type: application/json'
$ curl -X PUT --cacert dcos-ca.pem \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
  $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:admin:events \
  -d '{"description":"Allows access to Marathon events"}' \
  -H 'Content-Type: application/json'

# grant the service account read permissions (marathon services & events)
$ curl -X PUT --cacert dcos-ca.pem \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
  $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F/users/marathon-lb/read
$ curl -X PUT --cacert dcos-ca.pem \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
  $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:admin:events/users/marathon-lb/read
```

Now that the service account, secret, and permissions have been created, Marathon-LB must be configured to be injected with the secret in order to authenticate as the service account:

```
# create package config
$ cat >/tmp/marathon-lb.json <<EOF
{
    "marathon-lb": {
        "mem": 256,
        "secret_name": "marathon-lb-private-key"
    }
}
EOF

# install marathon-lb
$ dcos package install --options=/tmp/marathon-lb.json marathon-lb --yes
```
