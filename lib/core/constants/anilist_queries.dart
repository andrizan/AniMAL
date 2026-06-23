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
            description
            format
            startDate { year month day }
          }
        }
      }
    }
  ''';

  static const charactersAndStaff = r'''
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
            node { id name isAnimationStudio siteUrl image { medium } }
          }
        }
        nextAiringEpisode { airingAt episode timeUntilAiring }
        externalLinks { id url site type language icon }
      }
    }
  ''';

  static const nextAiring = r'''
    query ($idMal: Int) {
      Media(idMal: $idMal, type: ANIME) {
        nextAiringEpisode { airingAt episode timeUntilAiring }
      }
    }
  ''';

  static const characterDetail = r'''
    query ($id: Int) {
      Character(id: $id) {
        id name { full native } image { large medium }
        description dateOfBirth { year month day } age gender
        media(sort: POPULARITY_DESC, perPage: 10) {
          edges {
            characterRole
            node { id idMal title { romaji english } coverImage { medium } type }
          }
        }
      }
    }
  ''';

  static const staffDetail = r'''
    query ($id: Int) {
      Staff(id: $id) {
        id name { full native } image { large medium }
        description primaryOccupations gender
        dateOfBirth { year month day } dateOfDeath { year month day }
        age yearsActive homeTown
        staffMedia(sort: POPULARITY_DESC, perPage: 10) {
          edges {
            staffRole
            node { id idMal title { romaji english } coverImage { medium } type }
          }
        }
      }
    }
  ''';

  static const studioDetail = r'''
    query ($id: Int) {
      Studio(id: $id) {
        id name isAnimationStudio siteUrl favourites
        image { large medium }
        media(sort: POPULARITY_DESC, perPage: 10) {
          edges {
            node { id idMal title { romaji english } coverImage { medium } type }
          }
        }
      }
    }
  ''';
}
