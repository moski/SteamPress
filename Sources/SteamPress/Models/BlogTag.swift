
import Foundation
import Vapor
import FluentProvider

// MARK: - Model

final class BlogTag: Model {
    
    enum Properties: String {
        case id = "id"
        case name = "name"
        case urlEncodedName = "url_encoded_name"
        case postCount = "post_count"
    }
    
    let storage = Storage()
    
    var name: String
    
    init(name: String) {
        self.name = name    }
    
    required init(row: Row) throws {
        name = try row.get(Properties.name.rawValue)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Properties.name.rawValue, name)
        return row
    }
}

extension BlogTag: Parameterizable {
    static var uniqueSlug: String = "blogtag"
    
    static func make(for parameter: String) throws -> BlogTag {
        guard let blogTag = try BlogTag.makeQuery().filter(BlogTag.idKey, parameter).first() else {
            throw Abort.notFound
        }
        return blogTag
    }
}

// MARK: - Node

enum BlogTagContext: Context {
    case withPostCount
}

extension BlogTag: NodeRepresentable {
    func makeNode(in context: Context?) throws -> Node {
        
        var node = Node([:], in: context)
        try node.set(Properties.id.rawValue, id)
        try node.set(Properties.name.rawValue, name)
        
        guard let urlEncodedName = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            return node
        }
        
        try node.set(Properties.urlEncodedName.rawValue, urlEncodedName)
        
        guard let providedContext = context else {
            return node
        }
        
        switch providedContext {
        case BlogTagContext.withPostCount:
            try node.set(Properties.postCount.rawValue, sortedPosts().count())
        default: break
        }
        
        return node
    }
}

// MARK: - Relations

extension BlogTag {
    
    var posts: Siblings<BlogTag, BlogPost, Pivot<BlogTag, BlogPost>> {
        return siblings()
    }
    
    func sortedPosts() throws -> Query<BlogPost> {
        return try posts.filter(BlogPost.Properties.published.rawValue, true).sort(BlogPost.Properties.created.rawValue, .descending)
    }
    
    func deletePivot(for post: BlogPost) throws {
        try posts.remove(post)
    }
    
    static func addTag(_ name: String, to post: BlogPost) throws {
        var pivotTag: BlogTag
        let tag = try BlogTag.makeQuery().filter(Properties.name.rawValue, name).first()
        
        if let existingTag = tag {
            pivotTag = existingTag
        }
        else {
            let newTag = BlogTag(name: name)
            try newTag.save()
            pivotTag = newTag
        }
        
        // Check if a new tag
        let pivot = try pivotTag.posts.add(post)
        try pivot.save()
    }
}
