# neom_genres
neom_genres is a specialized module within the Open Neom ecosystem,
designed to manage and present user preferences related to genres. 
It provides a user-friendly interface for selecting, adding, removing,
and designating a "main" genre, allowing for granular personalization 
of a user's profile and facilitating connections within the community
based on shared interests or expertise.

This module is crucial for enhancing the personalization aspect of user profiles,
particularly for "App Artist" and similar profiles, but its design is extensible
for other specialized roles where genre-based categorization is relevant.
It was specifically decoupled from neom_instruments to allow for independent
future expansion and specialization in genre management. neom_genres adheres strictly
to Open Neom's Clean Architecture principles, ensuring its logic is robust, testable,
and decoupled. It seamlessly integrates with neom_core for core user data and services,
and neom_commons for shared UI components, providing a cohesive and intuitive experience
for managing genre preferences.

🌟 Features & Responsibilities
neom_genres provides a comprehensive set of functionalities for managing genre preferences:
•	Genre Selection & Management: Allows users to browse a predefined list of genres 
    (loaded from a JSON asset) and add/remove them from their favorite list.
•	Main Genre Designation: Enables users to select one of their favorited genres as their "main genre,"
    which can be highlighted on their profile and used for matchmaking.
•	Personalized Display: Displays both the full list of genres and a filtered list of the user's favorited genres.
•	Data Persistence: Handles the storage and retrieval of user's genre preferences 
    to/from the backend (Firestore) via GenreFirestore.
•	Profile Integration: Updates the user's AppProfile in neom_core with their chosen genres
    and main feature, ensuring consistency across the application.
•	Sorting & Filtering: Provides logic to sort genres, prioritizing favorited ones for easier access.
•	UI Components: Offers reusable FilterChip widgets for genre selection, enhancing user interaction.

🛠 Technical Highlights / Why it Matters (for developers)
For developers, neom_genres serves as an excellent case study for:
•	Dedicated Feature Module: Demonstrates how to create a highly focused module for a specific domain (genres),
    promoting modularity and independent development.
•	GetX for State Management: Utilizes GetX's GenreController for managing reactive state (RxMap for genres,
    RxBool for loading) and orchestrating user interactions (adding/removing genres, setting main genre).
•	Local Asset Loading: Shows how to load and parse data from local JSON assets
    (DataAssets.genresJsonPath) to populate UI elements.
•	Firestore Integration: Provides examples of reading and writing data to Firestore (GenreFirestore)
    for persisting user preferences.
•	Service Layer Interaction: Illustrates seamless interaction with UserService and AppDrawerService
    from neom_core to update the current user's profile and ensure UI consistency.
•	Dynamic UI Updates: Demonstrates how UI elements react to changes in user preferences
    (e.g., adding/removing a genre, setting a main genre).
•	Decoupling from neom_instruments: Highlights the benefit of separating distinct functionalities
    into their own modules for better organization and future scalability.

How it Supports the Open Neom Initiative
neom_genres is vital to the Open Neom ecosystem and the broader Tecnozenismo vision by:
•	Enhancing Profile Personalization: Allows users to express their unique tastes and interests,
    making their profiles more informative and engaging.
•	Facilitating Connections: Enables the platform to connect users based on shared genre preferences,
    fostering community and collaboration.
•	Supporting Content Discovery: Can be used to filter and recommend content 
    (e.g., posts, items, events) based on user-selected genres.
•	Promoting Data Organization: Provides a structured way to categorize and manage content
    and user preferences based on genres.
•	Showcasing Architectural Excellence: As a well-defined, decoupled module, it contributes 
    to the overall modularity and extensibility of Open Neom, inviting further contributions
    related to user preferences and content categorization.

🚀 Usage
This module provides the GenreController and related UI components (like genreChips) for managing user genre preferences.
It is typically accessed from the user's profile editing section (neom_profile), during the onboarding process (neom_onboarding),
or by other modules needing genre filtering/display capabilities.

📦 Dependencies
neom_genres relies on neom_core for core services, models, and routing constants, and on neom_commons for reusable
UI components, themes, and utility functions.

🤝 Contributing
We welcome contributions to the neom_genres module! If you're passionate about categorization,
user preferences, or enhancing content discoverability, your contributions can significantly 
improve how users express themselves and connect within Open Neom.

To understand the broader architectural context of Open Neom and how neom_genres fits into the overall
vision of Tecnozenism, please refer to the main project's MANIFEST.md.

For guidance on how to contribute to Open Neom and to understand the various levels of learning
and engagement possible within the project, consult our comprehensive guide: Learning Flutter Through Open Neom: A Comprehensive Path.

📄 License
This project is licensed under the Apache License, Version 2.0, January 2004. See the LICENSE file for details.
