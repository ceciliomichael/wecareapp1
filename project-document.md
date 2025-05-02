**Project Document: WeCare - Helper & Employer Connection Platform**

**Version:** 1.0
**Date:** 2024-08-30 (Using current date as requested)

**Table of Contents**

1.  Executive Summary
2.  Introduction & Vision
3.  Project Scope & Objectives
4.  Target Audience & Market Analysis
5.  Core Features & Functionality (Revised)
6.  Business Model & Monetization Strategy (Revised)
7.  User Experience (UX) & User Interface (UI) Design Philosophy
8.  Technical Specifications
9.  Development Plan & Methodology
10. Non-Functional Requirements
11. Verification, Security & Compliance (Revised)
12. Testing Strategy
13. Deployment & Maintenance Strategy
14. Risks & Mitigation Strategies
15. Success Metrics & Evaluation Plan
16. Thesis Considerations
17. Conclusion

---

**1. Executive Summary**

WeCare aims to be a trusted, user-friendly mobile platform (iOS & Android via Flutter) connecting individuals and families ("Employers") seeking domestic assistance with verified domestic workers ("Helpers"). Addressing the need for transparency, safety, and convenience in the domestic help sector, WeCare differentiates itself through robust Helper verification (including NBI clearance integration/process), detailed profiles, flexible booking, transparent ratings, direct communication, and dedicated support. This document outlines the vision, scope, features, technical approach, development plan, and critical considerations for building WeCare, serving as a foundational guide for the thesis project and potential future development. Key decisions regarding the monetization model ("Payment per posting" clarification needed) and the exact NBI verification workflow are highlighted as critical next steps.

**2. Introduction & Vision**

*   **Problem:** Finding reliable, trustworthy domestic help can be challenging, often relying on word-of-mouth or agencies with varying levels of transparency and cost. Employers struggle with verifying Helper backgrounds and finding suitable matches for specific needs. Helpers face difficulties in finding fair employment opportunities efficiently and safely.
*   **Solution:** The WeCare mobile application provides a centralized platform for Employers and Helpers to connect directly. It facilitates discovery through location-based search and detailed profiles, builds trust via verification processes and user reviews, and streamlines the hiring process through in-app communication and booking tools.
*   **App Name:** WeCare (Thesis Placeholder - *Note: Name conflicts with existing apps*)
*   **Vision:** To be the leading digital platform for ethical, transparent, and efficient connection between households and domestic Helpers, fostering respectful and secure employment relationships.
*   **Mission:** To empower Employers to find verified and suitable Helpers with ease and confidence, while providing Helpers with access to fair job opportunities and a secure platform to showcase their skills and experience.
*   **Core Value Proposition:** Trust, Convenience, Transparency, Flexibility, Security.

**3. Project Scope & Objectives**

*   **In Scope:**
    *   Development of a cross-platform (iOS/Android) mobile application using Flutter.
    *   Backend development to support all app functionalities (user management, profiles, search, booking, messaging, ratings, notifications, payments, verification links).
    *   Implementation of core features as defined in Section 5.
    *   User roles: Employer and Helper.
    *   Geographic focus: [Specify initial target region, e.g., Metro Manila, Philippines, based on NBI context].
    *   Integration with necessary third-party services (maps, payments, push notifications, potential verification APIs).
*   **Out of Scope (for initial MVP/Thesis Scope - can be future phases):**
    *   Placement agency portal/integration (though HelperPlace connects with agencies).
    *   Advanced HR functionalities (payroll, detailed contract management beyond basic templates/guidance).
    *   Integration with specific government job portals.
    *   Offline functionality.
    *   Web-based version of the platform.
*   **Project Objectives (SMART):**
    *   Develop and launch a functional Minimum Viable Product (MVP) of the WeCare app on iOS and Android within [Thesis Timeline, e.g., 6 months].
    *   Achieve [e.g., 100] registered and verified Helpers within 3 months post-launch.
    *   Achieve [e.g., 500] registered Employers within 3 months post-launch.
    *   Facilitate [e.g., 50] successful bookings through the platform within 3 months post-launch.
    *   Maintain an average user rating of [e.g., 4.0 stars] or higher in app stores.
    *   Successfully implement and document the chosen NBI verification workflow.

**4. Target Audience & Market Analysis**

*   **Target Users (Employers):**
    *   *Persona 1: Busy Urban Professionals/Families:* Need reliable help for cleaning, cooking, childcare. Value convenience, vetting, and easy scheduling.
    *   *Persona 2: Households with Elderly Members:* Require Helpers with caregiving skills, patience, and trustworthiness. Verification is paramount.
    *   *Persona 3: Expatriates/New Residents:* Need assistance navigating the local domestic help landscape, value clear profiles and guidance on regulations.
*   **Target Users (Helpers):**
    *   *Persona 4: Experienced Domestic Helpers:* Seeking better opportunities, fair wages, direct connection with employers, potentially finished contracts or transferring. Value showcasing skills and experience.
    *   *Persona 5: Part-time Helpers/Students:* Seeking flexible cleaning or task-based work. Value easy application and clear job descriptions.
    *   *Persona 6: Aspiring/New Domestic Helpers:* Need a platform to build their profile and find initial placements. Value guidance and support resources.
*   **Market Need:** Growing demand for domestic help, coupled with increasing desire for digital convenience and safety verification. Need for platforms that operate ethically (e.g., no placement fees for helpers, like HelperPlace).
*   **Competitor Analysis:**
    *   *Direct (Examples):* HelperPlace, HelperChoice, HelperLibrary, MaidProvider.ph (Agency with online presence), Local Agencies, Facebook Groups/Marketplace.
    *   *Indirect:* General job boards, classified ads.
    *   *HelperPlace Strengths:* Established user base, free for helpers, direct messaging, resume builder, connects with agencies, provides resources on contracts/visas. Operates in multiple regions.
    *   *Potential WeCare Differentiators:* Stronger emphasis on NBI/rigorous background checks [29 suggests agencies go beyond just NBI], potentially more advanced task customization/scheduling, potentially a different monetization model, superior UX/UI, focus on a specific niche (e.g., elderly care), localized support.

**5. Core Features & Functionality (Revised)**

*   **User Registration & Profiles:**
    *   *Employer Profile:* Basic info, location, preferences.
    *   *Helper Profile:* Detailed information: personal details, contact info, photo, skills (cleaning, cooking, childcare, elderly care, driving, etc.), years of experience, languages spoken, certifications/training, self-description/video introduction, desired salary range, availability (live-in, live-out, part-time), NBI Clearance status/link. *HelperPlace allows resume/CV creation within the app - consider this.*
*   **Verification System:**
    *   *NBI Clearance:*
        *   **Critical Decision Needed:** How will this be implemented?
            *   *Option A (Manual Upload & Admin Review):* Helper uploads a scan/photo of their valid NBI clearance. Admin team manually verifies authenticity (potentially using the NBI online verification tool if feasible and permitted) and updates status. *Requires admin resources.*
            *   *Option B (API Integration - Requires Research):* Investigate if NBI offers a secure API for third-party verification (unlikely based on current search results, which focus on individual online access). *High technical barrier, potential legal/policy issues.*
            *   *Option C (Guided Process):* Guide Helpers through the official NBI online application process, potentially requiring them to provide the clearance ID for verification via the public online tool.
        *   Status clearly displayed on Helper profile (e.g., "NBI Verified," "Verification Pending," "Not Verified").
    *   *Other Verifications (Future Phases/Enhanced Trust):* ID verification (government ID upload), reference checks (contacting previous employers - requires consent), skills assessment results. MaidProvider mentions visiting addresses and calling past employers.
*   **Location-Based Search & Filtering:**
    *   Employers find Helpers near their location using GPS/manual entry.
    *   Display results on a list and potentially an interactive map (`google_maps_flutter`).
    *   Filters: Distance, availability (days/hours, live-in/out), specific skills, experience level, ratings, NBI verified status, keywords. HelperPlace includes location, salary, start date filters.
*   **Real-time Updates (Presence):**
    *   Indicate Helpers currently online/available for quick communication or near-immediate booking (requires careful implementation for privacy and battery).
*   **Booking & Scheduling:**
    *   Employers request bookings for specific dates/times/durations.
    *   Option for one-time or recurring services (daily, weekly, bi-weekly).
    *   Helpers accept/decline booking requests.
    *   Calendar view for both parties to manage schedules.
*   **Task Customization:**
    *   Employers specify required tasks during booking (e.g., standard cleaning checklist, specific cooking requests, childcare duties).
    *   Ability to add custom notes/instructions.
*   **In-App Messaging:**
    *   Secure, real-time chat between Employers and Helpers for interviews, clarifications, instructions.
    *   Push notifications for new messages.
*   **Appointment Management:**
    *   Dashboard for upcoming and past appointments.
    *   Status updates (Requested, Accepted, In Progress, Completed, Cancelled).
    *   Notifications/reminders for upcoming services, arrival times, task completion confirmations.
*   **Ratings & Reviews:**
    *   Employers rate Helpers after service completion (e.g., 1-5 stars, written feedback).
    *   Helpers rate Employers (optional, promotes mutual respect).
    *   Ratings visible on profiles to help decision-making.
*   **Payment System:**
    *   **Critical Decision Needed:** Clarify "Payment per posting."
        *   *Model A (Employer Job Posting Fee):* Employers pay a fee to post a job listing visible to Helpers. HelperPlace seems to use a premium plan for employers to contact unlimited profiles.
        *   *Model B (Helper Subscription/Listing Fee):* Helpers pay to be listed or featured (Contravenes HelperPlace's "free for helpers" model, potentially unethical).
        *   *Model C (Commission per Transaction):* Platform takes a percentage of the payment for completed bookings facilitated through the app.
        *   *Model D (Freemium for Employers):* Basic posting/search is free, premium features (e.g., contacting more Helpers, featured posts, background check visibility) require subscription/payment.
    *   Integration with a secure payment gateway (Stripe, PayMongo, GCash etc.) for chosen model.
*   **Customer Support:**
    *   In-app help center/FAQ.
    *   Contact form or chat support for issues.
    *   Mechanism for dispute resolution between Employers and Helpers regarding services or payments.
*   **Resource Center (Value Add):** Like HelperPlace, provide access to information on standard employment contracts, local labor regulations, visa guidance (if applicable), training resources.

**6. Business Model & Monetization Strategy (Revised)**

*   Based on the decision for Feature #10 (Payment System), the primary monetization will be determined. Options include:
    *   **Employer Subscription/Posting Fees (Likely based on HelperPlace model):** Offer tiered plans for employers (e.g., free tier with limited contacts, paid tiers for unlimited contacts, featured job posts, access to more detailed Helper profiles/verification data).
    *   **Commission-Based:** Take a % cut from each successful transaction processed via the app. Requires robust payment integration and tracking.
    *   **Freemium:** Offer core functionality for free to attract a large user base, monetize through premium features for either Employers (preferred) or Helpers (less ethical), or in-app advertising (potentially intrusive). discuss various models.
    *   **Hybrid:** Combine models, e.g., free basic access, commission on bookings, optional premium features for employers.
*   **Secondary Revenue Streams (Potential):**
    *   Partnerships with training centers or related service providers.
    *   Anonymized data insights (aggregate level, respecting privacy).
    *   Sponsorships.

**7. User Experience (UX) & User Interface (UI) Design Philosophy**

*   **User-Centric:** Design decisions driven by target user needs and ease of use.
*   **Intuitive Navigation:** Simple, clear flows for key tasks (search, book, message, rate).
*   **Trust & Safety:** Visual cues reinforcing verification, secure processes.
*   **Clean & Professional Aesthetic:** Build credibility and user confidence.
*   **Accessibility:** Adhere to accessibility guidelines (font sizes, color contrast).
*   **Process:**
    1.  User Flow Diagrams
    2.  Wireframing (Low-fidelity layouts)
    3.  Mockups (High-fidelity visual designs)
    4.  Interactive Prototypes (Clickable demos)
    5.  Usability Testing (Iterative feedback with target users)

**8. Technical Specifications**

*   **Mobile Frontend:** Flutter (Dart) - for cross-platform development (iOS/Android).
    *   *Key Packages:* State Management (Riverpod/Bloc/Provider), HTTP (`dio`/`http`), Location (`geolocator`/`location`), Maps (`google_maps_flutter`), Notifications (`firebase_messaging`), Secure Storage (`flutter_secure_storage`), UI Components (`material`/`cupertino`, potentially UI kits), Chat (`dash_chat_2` or custom), Payments SDK (`flutter_stripe`, etc.).
*   **Backend:**
    *   *Option 1 (BaaS):* Firebase/Supabase - Faster initial development for auth, database (Firestore/RealtimeDB), functions, storage. Good for real-time needs (chat, location).
    *   *Option 2 (Custom):* Node.js (Express/NestJS), Python (Django/Flask), etc. - More control, potentially better long-term scalability/flexibility. Requires more setup/management.
    *   *Choice Factors:* Team expertise, thesis timeline, scalability needs, real-time requirements. Firebase is often a strong contender for MVPs.
*   **Database:**
    *   *If BaaS:* Firestore (NoSQL) or Firebase Realtime Database.
    *   *If Custom Backend:* PostgreSQL (Relational, good for structured data and geospatial queries with PostGIS) or MongoDB (NoSQL, flexible).
*   **Real-time Communication:** WebSockets (custom backend) or Firebase Realtime Database/Firestore listeners.
*   **Push Notifications:** Firebase Cloud Messaging (FCM).
*   **Payment Gateway:** Stripe, PayMongo, GCash API, etc. (Requires SDK integration and backend logic).
*   **Mapping/Location:** Google Maps Platform (Maps SDK, Geocoding API, Distance Matrix API). Monitor API usage costs.
*   **Hosting:** Firebase Hosting, Google Cloud Platform (GCP), AWS, Azure, Heroku (depends on backend choice).
*   **Architecture:** Likely a Client-Server model with the Flutter app communicating with the backend via REST APIs or GraphQL. Consider a clean architecture pattern (e.g., layered, MVVM/BLoC) within Flutter.

**9. Development Plan & Methodology**

*   **Methodology:** Agile (Scrum or Kanban). Sprints (e.g., 2 weeks) with planning, development, testing, and review cycles. Use project management tools (like Trello, Jira, Asana).
*   **Phased Rollout (Example):**
    *   **Phase 1 (Core MVP - ~3 months):**
        *   User Auth (Employer & Helper).
        *   Basic Profile Creation/Viewing (Manual NBI status initially).
        *   Location Search (List view) & Basic Filters.
        *   One-time Booking Request/Accept Flow (No payment integration yet).
        *   Basic In-App Messaging.
        *   Basic Ratings/Reviews submission & display.
        *   *Goal:* Validate core connection and booking flow.
    *   **Phase 2 (Enhancements - ~2 months):**
        *   Implement chosen NBI Verification flow (manual review or guided process).
        *   Map View for Search.
        *   Recurring Booking options.
        *   Appointment Management Dashboard & Notifications.
        *   Refined UI/UX based on initial feedback.
    *   **Phase 3 (Monetization & Support - ~1 month):**
        *   Integrate Payment Gateway based on chosen model.
        *   Implement Customer Support features (FAQ, contact form).
        *   Resource Center content population.
    *   **Phase 4 (Post-Thesis/Future):** Advanced filters, real-time presence, dispute resolution system, agency connections, additional verification methods, analytics.
*   **Team Roles (Typical Thesis Setup):** Define roles if multiple people are involved (e.g., Frontend Dev, Backend Dev, UI/UX Designer, Tester, Project Manager).
*   **Timeline:** Align phases with thesis deadlines.

**10. Non-Functional Requirements**

*   **Security:** Secure coding practices, HTTPS, data encryption (at rest/transit), input validation, dependency scanning, secure handling of PII and payment data.
*   **Performance:** <3s load time, smooth scrolling, responsive UI, efficient API calls, optimized battery usage (especially for location features).
*   **Scalability:** Backend architecture designed to handle growth in users and data. Database optimized for common queries.
*   **Reliability:** High uptime (>99.5%), robust error handling, crash reporting (Firebase Crashlytics), backups.
*   **Usability:** Intuitive design, minimal learning curve, consistency across the app.
*   **Maintainability:** Clean, well-documented code, modular architecture, automated testing.

**11. Verification, Security & Compliance (Revised)**

*   **NBI Clearance Process:** Define and document the *exact* workflow chosen (Manual Upload, Guided Process). Detail admin procedures if manual review is used. Ensure compliance with NBI's terms if using their online verification tool.
*   **Data Privacy:** Compliance with relevant data privacy laws (e.g., Philippines Data Privacy Act of 2012). Obtain user consent for data collection/processing. Secure storage of personal data. Clear privacy policy.
*   **Terms & Conditions:** Define terms of service for Employers and Helpers, outlining responsibilities, platform rules, payment terms, dispute process, liability limitations.
*   **Payment Security:** Use reputable payment gateways that are PCI-DSS compliant. Avoid storing raw credit card data.

**12. Testing Strategy**

*   **Unit Testing:** Test individual functions/classes (Flutter & Backend).
*   **Widget Testing:** Test individual Flutter widgets.
*   **Integration Testing:** Test interactions between different components/modules.
*   **End-to-End (E2E) Testing:** Simulate user flows across the entire system (Flutter app + Backend). Use tools like `flutter_driver` or `patrol`.
*   **Manual Testing:** Exploratory testing, usability testing.
*   **User Acceptance Testing (UAT):** Testing by target users (or peers in a thesis context) before launch.
*   **Security Testing:** Penetration testing (if feasible/required).
*   **Performance Testing:** Load testing the backend, profiling the Flutter app.

**13. Deployment & Maintenance Strategy**

*   **CI/CD:** Set up Continuous Integration/Continuous Deployment pipelines (e.g., GitHub Actions, Codemagic, Jenkins) for automated building, testing, and deployment.
*   **App Store Deployment:** Manage listings on Google Play Store and Apple App Store.
*   **Monitoring:** Implement backend logging and monitoring (e.g., Sentry, Datadog, GCP/AWS monitoring tools). Monitor app performance and crashes (Firebase Crashlytics, Performance Monitoring).
*   **Updates & Bug Fixes:** Plan for regular app updates to introduce features, fix bugs, and address security vulnerabilities.

**14. Risks & Mitigation Strategies**

*   **Technical Risks:**
    *   *NBI Integration Difficulty:* Mitigation: Thoroughly research feasibility early. Have backup manual process ready.
    *   *Scalability Issues:* Mitigation: Choose appropriate backend architecture; load test key services.
    *   *Cross-Platform Bugs:* Mitigation: Rigorous testing on both iOS/Android devices/simulators.
*   **Market Risks:**
    *   *Low User Adoption:* Mitigation: Strong value proposition, effective marketing (if applicable beyond thesis), user-friendly onboarding.
    *   *Competition:* Mitigation: Clear differentiation, focus on niche, excellent execution.
*   **Operational Risks:**
    *   *Verification Errors/Fraud:* Mitigation: Robust verification procedures, clear guidelines for admin review, user reporting mechanisms.
    *   *Disputes between Users:* Mitigation: Clear terms of service, defined dispute resolution process.
*   **Project Risks:**
    *   *Scope Creep:* Mitigation: Stick to defined MVP scope for thesis; manage backlog carefully.
    *   *Timeline Delays:* Mitigation: Realistic planning, Agile methodology, regular progress tracking.

**15. Success Metrics & Evaluation Plan**

*   **Key Performance Indicators (KPIs):**
    *   *User Acquisition:* # Registered Employers, # Registered Helpers, # Verified Helpers.
    *   *Engagement:* Daily Active Users (DAU), Monthly Active Users (MAU), Session duration, Feature usage rates (search, message, book).
    *   *Platform Activity:* # Job Postings (if applicable), # Booking Requests, # Completed Bookings, Booking success rate.
    *   *Quality & Satisfaction:* Average User Ratings (App Store & In-App), Customer Support ticket volume/resolution time, Churn Rate.
    *   *Monetization (If applicable):* Conversion Rate (free to paid), Average Revenue Per User (ARPU), Total Revenue.
*   **Evaluation:** Track KPIs using analytics tools (Firebase Analytics, custom backend dashboards). Conduct user surveys/interviews for qualitative feedback. Align evaluation with thesis objectives.

**16. Thesis Considerations**

*   **Research Question:** Define a clear research question this project aims to answer (e.g., "How can a mobile platform improve the safety and efficiency of connecting domestic helpers and employers in [Region]?"; "Evaluating the usability and effectiveness of different NBI verification workflows within a helper-finding application"; "Comparative analysis of monetization models for gig economy platforms in the domestic help sector").
*   **Methodology:** Detail the research methodology (e.g., Design Science Research, Case Study, User-Centered Design process evaluation).
*   **Contribution:** Articulate the project's contribution to knowledge (e.g., novel system design, empirical evaluation of features, insights into user behavior in this specific context).
*   **Evaluation:** Explain how the success metrics (Section 15) and testing results (Section 12) will be used to evaluate the research question and project outcomes. Use tools like Evernote or Trello for organizing research and tasks.

**17. Conclusion**

The WeCare project presents a significant opportunity to address real-world challenges in the domestic help sector through technology. By focusing on trust, verification, and user experience, the platform can provide substantial value to both Employers and Helpers. This document provides a comprehensive roadmap, but success hinges on addressing the critical decisions regarding monetization and NBI verification promptly, followed by diligent execution using an iterative development process. This project holds strong potential for a valuable thesis contribution and a foundation for a potentially impactful service.