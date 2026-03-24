# Architecture

## High-Level Components

- `AppViewModel`: App orchestration and startup wiring
- `MarmotService`: Protocol orchestration (Nostr + MLS event handling)
- `MLSService`: MLS group and crypto operations
- `RelayService`: Relay connectivity, subscriptions, and event publish/fetch
- `GroupListViewModel`, `GroupDetailViewModel`, `ChatViewModel`: UI-facing state and actions

## Core Data and State Stores

- `AppSettings`: persisted app settings and event processing metadata
- `PendingInviteStore`: pending joins before Welcome is accepted
- `PendingLeaveStore`: pending leave requests awaiting admin confirmation
- `NicknameStore`: pubkey-to-display-name mapping
- `LocationCache`: latest location by group/member

## Event Kinds (Marmot)

- `443`: KeyPackage publish/fetch
- `444`: Welcome (gift-wrapped)
- `445`: Group events (commits, proposals, app messages)
- `10051`: KeyPackage relay list

## Key Flows

1. Invitee accepts invite, publishes key package.
2. Admin adds member by key package.
3. Welcome event is gift-wrapped and delivered.
4. Invitee accepts Welcome, group appears in list.
5. Chat/location messages flow as kind `445` app messages.

## Reliability Notes

- `fetchMissedGiftWraps()` is used as catch-up for missed Welcome events.
- Pending gift-wrap IDs are retried after key package refresh.
- Membership changes trigger group refresh and view-model updates.
