import Vapor

public protocol BlogTagRepository {
    func getAllTags(on container: Container) -> EventLoopFuture<[BlogTag]>
    func getAllTagsWithPostCount(on container: Container) -> EventLoopFuture<[(BlogTag, Int)]>
    func getTags(for post: BlogPost, on container: Container) -> EventLoopFuture<[BlogTag]>
    func getTagsForAllPosts(on container: Container) -> EventLoopFuture<[Int: [BlogTag]]>
    func getTag(_ name: String, on container: Container) -> EventLoopFuture<BlogTag?>
    func save(_ tag: BlogTag, on container: Container) -> EventLoopFuture<BlogTag>
    // Delete all the pivots between a post and collection of tags - you should probably delete the
    // tags that have no posts associated with a tag
    func deleteTags(for post: BlogPost, on container: Container) -> EventLoopFuture<Void>
    func remove(_ tag: BlogTag, from post: BlogPost, on container: Container) -> EventLoopFuture<Void>
    func add(_ tag: BlogTag, to post: BlogPost, on container: Container) -> EventLoopFuture<Void>
}

public protocol BlogPostRepository {
    func getAllPostsSortedByPublishDate(includeDrafts: Bool, on container: Container) -> EventLoopFuture<[BlogPost]>
    func getAllPostsCount(includeDrafts: Bool, on container: Container) -> EventLoopFuture<Int>
    func getAllPostsSortedByPublishDate(includeDrafts: Bool, on container: Container, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]>
    func getAllPostsSortedByPublishDate(for user: BlogUser, includeDrafts: Bool, on container: Container, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]>
    func getPostCount(for user: BlogUser, on container: Container) -> EventLoopFuture<Int>
    func getPost(slug: String, on container: Container) -> EventLoopFuture<BlogPost?>
    func getPost(id: Int, on container: Container) -> EventLoopFuture<BlogPost?>
    func getSortedPublishedPosts(for tag: BlogTag, on container: Container, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]>
    func getPublishedPostCount(for tag: BlogTag, on container: Container) -> EventLoopFuture<Int>
    func findPublishedPostsOrdered(for searchTerm: String, on container: Container, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]>
    func getPublishedPostCount(for searchTerm: String, on container: Container) -> EventLoopFuture<Int>
    func save(_ post: BlogPost, on container: Container) -> EventLoopFuture<BlogPost>
    func delete(_ post: BlogPost, on container: Container) -> EventLoopFuture<Void>
}

public protocol BlogUserRepository {
    func getAllUsers(on container: Container) -> EventLoopFuture<[BlogUser]>
    func getAllUsersWithPostCount(on container: Container) -> EventLoopFuture<[(BlogUser, Int)]>
    func getUser(id: Int, on container: Container) -> EventLoopFuture<BlogUser?>
    func getUser(username: String, on container: Container) -> EventLoopFuture<BlogUser?>
    func save(_ user: BlogUser, on container: Container) -> EventLoopFuture<BlogUser>
    func delete(_ user: BlogUser, on container: Container) -> EventLoopFuture<Void>
    func getUsersCount(on container: Container) -> EventLoopFuture<Int>
}

extension BlogUser: Parameter {
    public typealias ResolvedParameter = EventLoopFuture<BlogUser>
    public static func resolveParameter(_ parameter: String, on container: Container) throws -> BlogUser.ResolvedParameter {
        let userRepository = try container.make(BlogUserRepository.self)
        guard let userID = Int(parameter) else {
            throw SteamPressError(identifier: "Invalid-ID-Type", "Unable to convert \(parameter) to a User ID")
        }
        return userRepository.getUser(id: userID, on: container).unwrap(or: Abort(.notFound))
    }
}

extension BlogPost: Parameter {
    public typealias ResolvedParameter = EventLoopFuture<BlogPost>
    public static func resolveParameter(_ parameter: String, on container: Container) throws -> EventLoopFuture<BlogPost> {
        let postRepository = try container.make(BlogPostRepository.self)
        guard let postID = Int(parameter) else {
            throw SteamPressError(identifier: "Invalid-ID-Type", "Unable to convert \(parameter) to a Post ID")
        }
        return postRepository.getPost(id: postID, on: container).unwrap(or: Abort(.notFound))
    }
}

extension BlogTag: Parameter {
    public typealias ResolvedParameter = EventLoopFuture<BlogTag>
    public static func resolveParameter(_ parameter: String, on container: Container) throws -> EventLoopFuture<BlogTag> {
        let tagRepository = try container.make(BlogTagRepository.self)
        return tagRepository.getTag(parameter, on: container).unwrap(or: Abort(.notFound))
    }
}
