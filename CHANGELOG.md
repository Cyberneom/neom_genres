### 1.0.0 - Initial Release & Decoupling from neom_instruments
This marks the initial official release (v1.0.0) of neom_genres as a new, independent module within the Open Neom ecosystem. Previously, genre management functionalities were often intertwined with other preference modules like neom_instruments. This decoupling is a crucial step in formalizing the genre management layer, enhancing modularity, and strengthening Open Neom's adherence to Clean Architecture principles.

Key Highlights of this Release:

New Module Introduction & Specialization:

neom_genres is now a dedicated module for all genre-related processes, ensuring a clear separation of concerns from other preference or profile modules.

This allows for specialized development and maintenance of genre-specific features.

Decoupling from neom_instruments:

Genre management logic and UI components have been entirely separated from neom_instruments. This ensures that each module has a single, well-defined responsibility.

Centralized Genre Management:

Provides a dedicated and robust interface for managing user genre preferences, including:

Loading genres from local assets.

Adding and removing favorite genres.

Designating a "main" genre for a user's profile.

Persisting genre preferences to Firestore.

Module-Specific Translations:

Introduced GenreTranslationConstants to centralize and manage all UI text strings specific to genre functionalities. This ensures improved localization, maintainability, and consistency with Open Neom's global strategy.

Enhanced Maintainability & Future Scalability:

As a dedicated and self-contained module, neom_genres is now significantly easier to maintain, test, and extend for future genre-related features (e.g., genre-based recommendations, advanced filtering).

Any module requiring genre preferences can simply depend on neom_genres and its GenreService.

Leverages Core Open Neom Modules:

Built upon neom_core for foundational services (like UserService and AppDrawerService for profile updates) and neom_commons for reusable UI components and utilities, ensuring seamless integration within the ecosystem.