# Polarix Trucker Job

<table>
  <tr>
    <td><img src="https://i.imgur.com/T4O4AxJ.png" alt="Dashboard Image" width="100%"/></td>
    <td><img src="https://i.imgur.com/9MWyYIw.png" alt="Companies & Convoy Image" width="100%"/></td>
  </tr>
  <tr>
    <td><img src="https://i.imgur.com/fp9ClAy.png" alt="Forklift Image" width="100%"/></td>
    <td><img src="https://i.imgur.com/g8SiqUA.png" alt="Admin UI Image" width="100%"/></td>
  </tr>
</table>

A deep trucking job for FiveM. Real cargo hauling with forklift pallet loading, a skill tree that actually changes gameplay, driver companies, party convoys, and a slick Vue-based dashboard — not a copy-paste job script.

Works with **qbox**, **qb-core**, and **ESX** out of the box.

## Features

- **Real deliveries** — drive to a pickup zone, load pallets with a forklift, haul to drop-off. Fragile and live cargo take damage if you drive recklessly or crash, cutting into your payout.
- **Skill tree** — three branches (Hauling, Economy, Endurance) with perks that reduce cargo damage, cut fuel costs, boost payouts and XP, and unlock hazmat/long-haul routes.
- **Vehicles & trailers** — buy trucks and trailers with capacity limits; trailer type determines how many pallets fit. No truck or trailer of your own? Rent a bundle on the spot.
- **Companies** — form a trucking company with a shared bank, member roles, invitations, and stats.
- **Party convoys** — team up with up to 5 players, split loading duty across a shared pallet pool, and earn a group reward bonus.
- **Admin mission editor** — build and edit delivery routes in-game with a live preview of pickup/drop-off. Changes go live instantly, no resource restart needed.
- **Multi-language** — dashboard and notifications support multiple languages out of the box, easily expandable.
- **Polished dashboard** — for orders, skills, fleet, and company management.
- **Props included** — invincible rescaled native props made by [StraussMoewe](https://sm3d.tebex.io)

## Requirements

- [`ox_lib`](https://github.com/overextended/ox_lib)
- [`oxmysql`](https://github.com/overextended/oxmysql)
- One of: `qbx_core` (qbox), `qb-core`, or `es_extended` (ESX)

## Installation

1. Download the current version via the the release section on the right side of this repo page.
2. Drop the resource into your server's `resources/` folder as `polarix_truckerjob`.
3. Add to your `server.cfg`:
   ```
   ensure ox_lib
   ensure oxmysql
   ensure polarix_truckerjob
   ```
4. Take a look at the  `config/` files and adjust your framework setting and setup other settings to your liking.
5. Start your server. Database tables are created automatically the first time the resource starts — no manual SQL import needed.

## Configuration

Everything is tunable from three files, no code changes required:

| File | What you can change |
|---|---|
| [config/shared.lua](config/shared.lua) | Language, Skill tree & perks, XP curve, rental pricing, trailer capacities, party size and reward bonus |
| [config/server.lua](config/server.lua) | Framework, admin access, vehicle shop lineup |
| [config/client.lua](config/client.lua) | Truck depot location and blip |

## Admin mission editor

Server admins open the in-game editor with `/truckeradmin` to create, edit, or disable delivery routes — including a live position preview. Changes apply immediately, no restart or SQL editing required.

## Support

Report bugs or request features via [GitHub Issues](https://github.com/derPolarix/polarix_truckerjob/issues).


<a href="https://www.star-history.com/?repos=derPolarix%2Fpolarix_truckerjob&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=derPolarix/polarix_truckerjob&type=date&theme=dark&legend=top-left&sealed_token=eA5RsmWg_AWJI09nHpRM2xN8UtgwAJPz_b9XBmdjUkgjT5RsmIaLZzapg55CwItuwfw2f3qgwwG-2hKNxzd1MRpKJIABQT4Y7iUFKOfUm3Kpmic4FMSXR6-lMP1O8j1XXtZrbNSar5MhbFkCSlG4Pc48iiHxvGgmPz9yp364OFm71h67PdQ59cwTZKJz" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=derPolarix/polarix_truckerjob&type=date&legend=top-left&sealed_token=eA5RsmWg_AWJI09nHpRM2xN8UtgwAJPz_b9XBmdjUkgjT5RsmIaLZzapg55CwItuwfw2f3qgwwG-2hKNxzd1MRpKJIABQT4Y7iUFKOfUm3Kpmic4FMSXR6-lMP1O8j1XXtZrbNSar5MhbFkCSlG4Pc48iiHxvGgmPz9yp364OFm71h67PdQ59cwTZKJz" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=derPolarix/polarix_truckerjob&type=date&legend=top-left&sealed_token=eA5RsmWg_AWJI09nHpRM2xN8UtgwAJPz_b9XBmdjUkgjT5RsmIaLZzapg55CwItuwfw2f3qgwwG-2hKNxzd1MRpKJIABQT4Y7iUFKOfUm3Kpmic4FMSXR6-lMP1O8j1XXtZrbNSar5MhbFkCSlG4Pc48iiHxvGgmPz9yp364OFm71h67PdQ59cwTZKJz" />
 </picture>
</a>
