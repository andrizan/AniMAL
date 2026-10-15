abstract final class AniListQueries {
  static const airingSchedule = r'''
    query ($startAt: Int, $endAt: Int, $page: Int) {
      Page(page: $page, perPage: 50) {
        pageInfo { hasNextPage }
        airingSchedules(
          airingAt_greater: $startAt
          airingAt_lesser: $endAt
          sort: TIME
        ) {
          id
          airingAt
          episode
          timeUntilAiring
          media {
            id
            idMal
            title { romaji english native }
            coverImage { medium large }
            status
            episodes
            meanScore
            genres
            format
            startDate { year month day }
            nextAiringEpisode { airingAt episode timeUntilAiring }
          }
        }
      }
    }
  ''';

  static const animeExtra = r'''
    query ($idMal: Int) {
      Media(idMal: $idMal, type: ANIME) {
        characters(sort: ROLE, perPage: 25) {
          edges {
            role
            node { id name { full native } image { medium } }
            voiceActors(language: JAPANESE) {
              id name { full native } image { medium } language
            }
          }
        }
        staff(sort: RELEVANCE, perPage: 20) {
          edges {
            role
            node { id name { full native } image { medium } }
          }
        }
        studios(isMain: true) {
          edges {
            isMain
            node { id name isAnimationStudio siteUrl }
          }
        }
        nextAiringEpisode { airingAt episode timeUntilAiring }
        externalLinks { id url site type language icon }
      }
    }
  ''';

  static const characterDetail = r'''
    query ($id: Int, $perPage: Int) {
      Character(id: $id) {
        id name { full native } image { large medium }
        description dateOfBirth { year month day } age gender
        media(sort: POPULARITY_DESC, perPage: $perPage) {
          pageInfo { hasNextPage }
          edges {
            characterRole
            node {
              id idMal title { romaji english native } coverImage { medium }
              type format episodes status meanScore
            }
          }
        }
      }
    }
  ''';

  static const staffDetail = r'''
    query ($id: Int, $perPage: Int) {
      Staff(id: $id) {
        id name { full native } image { large medium }
        description primaryOccupations gender
        dateOfBirth { year month day } dateOfDeath { year month day }
        age yearsActive homeTown
        staffMedia(sort: POPULARITY_DESC, perPage: $perPage) {
          pageInfo { hasNextPage }
          edges {
            staffRole
            node {
              id idMal title { romaji english native } coverImage { medium }
              type format episodes status meanScore
            }
          }
        }
      }
    }
  ''';

  static const studioDetail = r'''
    query ($id: Int, $perPage: Int) {
      Studio(id: $id) {
        id name isAnimationStudio siteUrl favourites
        media(sort: POPULARITY_DESC, perPage: $perPage) {
          pageInfo { hasNextPage }
          edges {
            node {
              id idMal title { romaji english native } coverImage { medium }
              type format episodes status meanScore
            }
          }
        }
      }
    }
  ''';

  // Later pages of the works lists. The detail queries above already carry
  // page 1 with the same sort and a `perPage` of `AniListClient.worksPageSize`
  // (AniList's maximum), so page 2 starts exactly where the detail stopped.

  static const characterWorksPage = r'''
    query ($id: Int, $page: Int, $perPage: Int) {
      Character(id: $id) {
        media(sort: POPULARITY_DESC, page: $page, perPage: $perPage) {
          pageInfo { hasNextPage total }
          edges {
            characterRole
            node {
              id idMal title { romaji english native } coverImage { medium }
              type format episodes status meanScore
            }
          }
        }
      }
    }
  ''';

  static const staffWorksPage = r'''
    query ($id: Int, $page: Int, $perPage: Int) {
      Staff(id: $id) {
        staffMedia(sort: POPULARITY_DESC, page: $page, perPage: $perPage) {
          pageInfo { hasNextPage total }
          edges {
            staffRole
            node {
              id idMal title { romaji english native } coverImage { medium }
              type format episodes status meanScore
            }
          }
        }
      }
    }
  ''';

  static const studioWorksPage = r'''
    query ($id: Int, $page: Int, $perPage: Int) {
      Studio(id: $id) {
        media(sort: POPULARITY_DESC, page: $page, perPage: $perPage) {
          pageInfo { hasNextPage total }
          edges {
            node {
              id idMal title { romaji english native } coverImage { medium }
              type format episodes status meanScore
            }
          }
        }
      }
    }
  ''';
}
