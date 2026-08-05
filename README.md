<picture>
<img width="300" height="300" alt="Timetable-iOS-Dark-1024@1x" src="https://github.com/user-attachments/assets/295ed7a0-2fec-46b9-bfcd-0bde11f9db13" />
<img width="250" height="250" alt="Timetable-watchOS-Default-1088@1x" src="https://github.com/user-attachments/assets/f904cf9c-355e-4dfc-ad2a-34cf82960648" />
</picture>



# Timetable for PMS

- iOS, iPadOS, macOS, watchOS app for tracking the school timetable for my school.

> [!Note]
> Only available for OS27 and later on iOS, macOS, and iPadOS, and OS26 and later on watchOS.
> This is due to too many APIs requiring the new OS.
> I apologise if you are on an earlier version.

> [!Note]
> The structure of this app is heavily centred around the timetable structure my specific school has, so it (probably?) won't work with other schools. This is so that I can optimise features and backend code to only need to handle one type of school.

<br>

- Import your calendar from Apple Calendar
- Check all of your classes, and your friends' classes
- Fully integrated with Siri and Apple Intelligence
- Live Activities throughout the school day showing next subject, etc
- Notifications for each period
- Events, like carnivals, pupil free days, etc
- iOS, macOS, watchOS widgets

#### Try it from TestFlight: https://testflight.apple.com/join/DDUXPSq3

<br>

This project also has a server, the source code for which is at [omeriadon/pmstt](https://github.com/omeriadon/pmstt).
It runs on Swift Vapor, using the same language as the client app, to allow for faster features.

The macOS app is actually Mac Catalyst, which means it runs an iPad app optimised for Mac. This makes development much faster, since the iPad version is also the iPhone version.

Watch uses its own target, because it's screen is much smaller and its not authoritative (It can't delete accounts or change settings, etc. It just shows the user fast info). It depends on the iPhone app being installed

<br>

## Build and Run
1. Open project in Xcode
2. Run watchOS or iOS/macOS scheme.

To change the base url to use your own hosted instance of `pmstt`, go to `NetworkManager` and change the base url.

The server requires a few things to work:
- A CloudFlare R2 bucket (for storing profile images)
- An APNs key (For sending notifications and Live Activities)
- Resend API Key (for sending emails)
- Change the admin emails to change the system administrators (the admins that can't change roles, normally reserved for 1-2 people. These system admins can then manage other admins, etc.
