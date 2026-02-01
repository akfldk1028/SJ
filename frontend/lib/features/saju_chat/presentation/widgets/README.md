# saju_chat/presentation/widgets

UI widgets for the saju chat screen. Chat bubbles, ad integration, input controls.

## Key Files

| File | Purpose |
|------|---------|
| `conversational_ad_widget.dart` | Main ad integration widget. `_handleAdComplete()` passes `isRewardedAd` to `addBonusTokens()`. v26 fix: prevents double-counting rewarded vs bonus tokens. |
| `message_bubble.dart` | Chat message display with markdown rendering. Handles user and AI messages. |
| `streaming_message_bubble.dart` | Real-time streaming display for Gemini SSE responses. Shows text as it arrives. |
| `chat_message_list.dart` | ListView of chat messages. Handles scroll position, auto-scroll on new messages. |
| `ad_native_bubble.dart` | Native ad container styled as a chat bubble. Blends with conversation UI. |
| `ad_transition_bubble.dart` | Persona transition message shown before ad display. Smooth UX transition. |
| `chat_input_field.dart` | Message input text field + send button. Handles submit logic. |
| `send_button.dart` | Animated send button with loading state. |
| `chat_app_bar.dart` | Chat screen app bar with persona info and session controls. |
| `chat_bubble.dart` | Base bubble styling shared by message types. |
| `thinking_bubble.dart` | "AI is thinking" animation during GPT analysis phase. |
| `typing_indicator.dart` | Typing dots animation during Gemini response. |
| `persona_avatar.dart` | AI persona avatar display. |
| `persona_selector_sheet.dart` | Bottom sheet for persona selection. |
| `relation_selector_sheet.dart` | Bottom sheet for selecting relationship target (compatibility chat). |
| `suggested_questions.dart` | Pre-built question chips for new conversations. |
| `disclaimer_banner.dart` | Legal disclaimer for fortune-telling content. |
| `error_banner.dart` | Error display banner for failed API calls. |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `chat_history_sidebar/` | Side panel showing past chat sessions. |
| `persona_selector/` | Persona selection UI components. |

## Ad Widget Flow

```
Token threshold reached (80% or 100%)
    |
conversational_ad_widget shows ad_transition_bubble
    |
    +-- Native ad: ad_native_bubble (impression tracked)
    +-- Rewarded ad: full-screen ad
    |
_handleAdComplete(isRewardedAd: true/false)
    |
chat_provider.addBonusTokens(amount, isRewardedAd: flag)
```

## Connections

- **Providers**: All widgets consume from `providers/` (chat_provider, conversational_ad_provider, persona providers)
- **Parent**: `screens/saju_chat_shell.dart` assembles these widgets
- **Ad module**: `ad/ad_tracking_service.dart` for impression/click tracking
