# NosflareDeploy

https://github.com/PastaGringo/nosflare/assets/16828964/fb476a92-6458-4a76-9216-9451039ac886

BETA Simple script to deploy the Nosflare serverless Nostr relay to Cloudflare Worker.  
Still is still in development and may be integrated to Nosflare repo when going to Production.

The script won't update your Nosflare until you change the source Github repo for Nosflare.  
Will be useful to test the upgrade for the next Nosflare release.

## How to use

### Download and make the script executable
```
wget https://raw.githubusercontent.com/PastaGringo/nosflare/main/DeployNosflare.sh
chmod +x ./DeployNosflare.sh
```

### Run the script
```
./DeployNosflare.sh

-------------------------- NosflareDeploy v1.0 ---------------------------
    _   __           ______                ____             __           
   / | / /___  _____/ __/ /___  ____ ___  / __ \___  ____  / /___  __  __
  /  |/ / __ \/ ___/ /_/ / __ \/ __// _ \/ / / / _ \/ __ \/ / __ \/ / / /
 / /|  / /_/ (__  ) __/ / /_/ / /  /  __/ /_/ /  __/ /_/ / / /_/ / /_/ / 
/_/ |_/\____/____/_/ /_/\__,_/_/   \___/_____/\___/ .___/_/\____/\__, /  
                                                 /_/            /____/   
-------------------------- NosflareDeploy v1.0 ---------------------------

Current dir: /home/pastadmin/Apps/TEMP
Hide my infos: disabled

Checking if variables have been set INTO the script (how-to: nano ./DeployNosflare.sh) ...

❌ VAR $CLOUDFLARE_API_TOKEN    :
❌ VAR $relayURL                :
❌ VAR $relayInfo_name          :
❌ VAR $relayInfo_description   :
❌ VAR $relayInfo_pubkey        :
❌ VAR $relayInfo_contact       :
❌ VAR $relayInfo_pubkey        :

[ERROR] At least one variable is missing. You need to set all the variables before starting the script. Exiting. Bye
```

### Update the script variables for your infos
```
# Please update variables below before running the script
##################################################################################################
# You can create your API token from your Cloudflare account here: https://dash.cloudflare.com/profile/api-tokens
# Use template "Edit Cloudflare Workers" or create a custom one for workers
CLOUDFLARE_API_TOKEN=""
relayInfo_name=""
# Full domain of the relay. Ex: relay.domain.tld. You need to have the domain.tld zone available in your Cloudflare domain list.
relayURL=""
relayInfo_description=""
#pubkey hex format, you can use damus convertor to convert your npub to hex : https://damus.io/key/
relayInfo_pubkey=""
relayInfo_contact=""
relayIcon_URL=""
# Set to 1 if you need to hide your info during the wrangler whoami & CF API KEY display (maybe you want to record your session script?)
hide_whoami_infos=0
```

### How to upgrade your Nosflare relay with the script
```
nano ./DeployNosflare.sh
```

### Upgrade your Nosflare relay with the script
UNTESTED YET ⚠️ Update the variable nosflare_remote_gh_repo to the official Nosflare github repo:
```
nosflare_remote_gh_repo="https://github.com/Spl0itable/nosflare"
```

Don't hesitate to open new issues if you find some bugs into the script ⚡

# Nosflare

Nosflare is a serverless [Nostr](https://github.com/fiatjaf/nostr) relay purpose-built for [Cloudflare Workers](https://workers.cloudflare.com/) and the [Cloudflare KV](https://www.cloudflare.com/products/workers-kv/) store. 

This relay is designed to be easy to deploy, scalable, and cost-effective, leveraging Cloudflare's edge computing infrastructure to provide a resilient relay for the Nostr decentralized social  protocol.

## Supported NIPs

- Supports a range of [Nostr Improvement Proposals (NIPs)](https://github.com/fiatjaf/nostr/tree/master/nips), including NIPs 1, 2, 4, 9, 11, 12, 15, 16, 20, 22, 33, and 40.

## Getting Started

### Prerequisites

- A [Cloudflare](https://www.cloudflare.com/plans/) account with Workers and KV Store enabled.
- [Node.js](https://nodejs.org/) and npm (for installing dependencies and running the build script).
- [Wrangler CLI](https://developers.cloudflare.com/workers/cli-wrangler/install-update) (optional) or access to the Cloudflare dashboard for deployment.

### Dependencies

This project requires the [@noble/curves](https://github.com/paulmillr/noble-curves) package for cryptographic operations:

```
npm install @noble/curves
```

### Building

Pull the `worker.js` file to your machine. Edit the contents of `relayInfo` and `relayIcon` as desired to customize the relay name, icon, etc.

We'll use `esbuild` to bundle the worker script:

```
esbuild worker.js --bundle --outfile=dist/worker.js --platform=neutral --target=es2020
```

The command assumes you're in the same directory as the `worker.js` file.

### Deployment

You can deploy Nosflare using either the Wrangler CLI or directly through the Cloudflare dashboard:

#### Using Wrangler

1. Configure your `wrangler.toml` with your Cloudflare account details.
2. Publish the worker:

```
wrangler publish
```
3. Add a custom domain or route (this will be the desired relay URL).
4. Create a KV namespace to store events. You can call it whatever you want.
5. Bind the `relayDb` variable to the KV namespace for the Worker in the Settings > Variables tab under the "KV Namespace Bindings" section.

#### Using Cloudflare Dashboard

1. Log in to your Cloudflare dashboard.
2. Go to the Workers section and create a new worker. You can call it whatever you'd like.
3. Copy the contents of `dist/worker.js` and paste into the online editor. See the `example.js` file in this repo for what a successfully bundled file should look like.
4. Save and deploy the worker.
5. Add a custom domain or route (this will be the desired relay URL).
6. Create a KV namespace to store events. You can call it whatever you want.
7. Bind the `relayDb` variable to the KV namespace for the Worker in the Settings > Variables tab under the "KV Namespace Bindings" section.

## Usage

Nosflare acts as a Nostr relay. Users can connect using any standard Nostr client by pointing to the deployed Cloudflare Worker URL. The relay adheres to the Nostr protocol, handling events according to the specified NIPs.

You can either use the Cloudflare Worker's default "workers.dev" endpoint URL or a custom domain and/or route to add the relay to any Nostr client using the secure websocket protocol.

Example:

- `wss://nostr-relay.example.workers.dev/`

## Roadmap

The current release of Nosflare is primarily focused on [basic protocol flow](https://github.com/nostr-protocol/nips/blob/master/01.md) usage. However, the following is a non-exhaustive list of planned features:

- Allowlisting and Blocklisting of event kinds and pubkeys
- "Pay-to-relay" (charging sats for access)
- Client authorization (NIP-42)
- File storage through Cloudflare R2 bucket (NIP-96)
- Encrypted DMs (NIP-44)

## Contributing

Contributions to Nosflare are welcome! Please submit issues, feature requests, or pull requests through the project's [GitHub repository](https://github.com/Spl0itable/nosflare).

## License

Nosflare is open-sourced software licensed under the MIT license.

## Contact

For inquiries related to Nosflare, you can reach out on Nostr at `npub16jdfqgazrkapk0yrqm9rdxlnys7ck39c7zmdzxtxqlmmpxg04r0sd733sv`

## Acknowledgements

- The awesome Nostr community for the protocol development.
- Cloudflare Workers for an easy-to-use serverless execution environment.
- The noble library for providing Schnorr signatures over secp256k1.
