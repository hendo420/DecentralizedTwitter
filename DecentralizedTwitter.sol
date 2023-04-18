pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract DecentralizedTwitter is ERC1155 {
    struct Post {
        uint256 id;
        address owner;
        string contentURI;
        uint256 timestamp;
        bool isPublic;
    }

    struct Comment {
        uint256 id;
        address owner;
        uint256 postId;
        string content;
        uint256 timestamp;
    }

    struct UserProfile {
        string displayName;
        string bio;
        string avatarURI;
    }

    struct User {
        UserProfile profile;
        uint256[] posts;
        mapping(address => bool) following;
        mapping(address => bool) blockedUsers;
    }

    mapping(uint256 => Post) public posts;
    mapping(uint256 => Comment) public comments;
    mapping(address => User) public users;
    uint256 public postIdCounter;
    uint256 public commentIdCounter;

    event NewPost(uint256 indexed postId, address indexed owner);
    event EditedPost(uint256 indexed postId, address indexed owner);
    event DeletedPost(uint256 indexed postId);
    event SharedPost(uint256 indexed originalPostId, uint256 indexed sharedPostId, address indexed sharer);
    event LikedPost(uint256 indexed postId, address indexed liker);
    event Follow(address indexed follower, address indexed following);
    event Unfollow(address indexed follower, address indexed unfollowing);
    event Block(address indexed blocker, address indexed blocked);
    event Unblock(address indexed blocker, address indexed unblocked);
    event NewComment(uint256 indexed commentId, uint256 indexed postId, address indexed commenter);
    event DeletedComment(uint256 indexed commentId);

    constructor() ERC1155("") {}

    // Allows users to create a new post
    function createPost(string memory _contentURI, bool _isPublic) external {
        postIdCounter++;
        uint256 newPostId = postIdCounter;
        posts[newPostId] = Post(newPostId, msg.sender, _contentURI, block.timestamp, _isPublic);
        users[msg.sender].posts.push(newPostId);
        _mint(msg.sender, newPostId, 1, "");

        emit NewPost(newPostId, msg.sender);
    }

    // Allows users to edit their own post
    function editPost(uint256 _postId, string memory _newContentURI) external {
        require(posts[_postId].owner == msg.sender, "You must be the owner of the post to edit it.");
        posts[_postId].contentURI = _newContentURI;

        emit EditedPost(_postId, msg.sender);
    }

    // Allows users to delete their own post
    function deletePost(uint256 _postId) external {
        require(posts[_postId].owner == msg.sender, "You must be the owner of the post to delete it.");
        _burn(msg.sender, _postId, 1);
        delete posts[_postId];

        emit DeletedPost(_postId);
    }

    // Allows users to share (retweet) a post
    function sharePost(uint256 _originalPostId) external {
        require(posts[_originalPostId].owner != address(0), "Original post does not exist.");
        require(posts[_originalPostId].isPublic, "Original post is not public.");
        require(!users[posts[_originalPostId].owner].blockedUsers[msg.sender], "You are blocked by the owner of the original post.");

        postIdCounter++;
        uint256 sharedPostId = postIdCounter;
        posts[sharedPostId] = Post(sharedPostId, msg.sender, posts[_originalPostId].contentURI, block.timestamp, true);
users[msg.sender].posts.push(sharedPostId);
_mint(msg.sender, sharedPostId, 1, "");


    emit SharedPost(_originalPostId, sharedPostId, msg.sender);
}

// Allows users to like a post
function likePost(uint256 _postId) external {
    require(posts[_postId].owner != address(0), "Post does not exist.");
    require(!users[posts[_postId].owner].blockedUsers[msg.sender], "You are blocked by the owner of the post.");
    _mint(msg.sender, _postId, 1, "");

    emit LikedPost(_postId, msg.sender);
}

// Allows users to follow another user
function follow(address _userToFollow) external {
    require(_userToFollow != msg.sender, "You cannot follow yourself.");
    require(!users[_userToFollow].blockedUsers[msg.sender], "You are blocked by the user.");
    users[msg.sender].following[_userToFollow] = true;

    emit Follow(msg.sender, _userToFollow);
}

// Allows users to unfollow another user
function unfollow(address _userToUnfollow) external {
    require(_userToUnfollow != msg.sender, "You cannot unfollow yourself.");
    users[msg.sender].following[_userToUnfollow] = false;

    emit Unfollow(msg.sender, _userToUnfollow);
}

// Allows users to block another user
function blockUser(address _userToBlock) external {
    require(_userToBlock != msg.sender, "You cannot block yourself.");
    users[msg.sender].blockedUsers[_userToBlock] = true;

    emit Block(msg.sender, _userToBlock);
}

// Allows users to unblock another user
function unblockUser(address _userToUnblock) external {
    require(_userToUnblock != msg.sender, "You cannot unblock yourself.");
    users[msg.sender].blockedUsers[_userToUnblock] = false;

    emit Unblock(msg.sender, _userToUnblock);
}

// Allows users to update their profile information
function updateProfile(string memory _displayName, string memory _bio, string memory _avatarURI) external {
    users[msg.sender].profile.displayName = _displayName;
    users[msg.sender].profile.bio = _bio;
    users[msg.sender].profile.avatarURI = _avatarURI;
}

// Allows users to add a comment to a post
function addComment(uint256 _postId, string memory _content) external {
    require(posts[_postId].owner != address(0), "Post does not exist.");
    require(!users[posts[_postId].owner].blockedUsers[msg.sender], "You are blocked by the owner of the post.");

    commentIdCounter++;
    uint256 newCommentId = commentIdCounter;
    comments[newCommentId] = Comment(newCommentId, msg.sender, _postId, _content, block.timestamp);

    emit NewComment(newCommentId, _postId, msg.sender);
}

// Allows users to delete their own comment
function deleteComment(uint256 _commentId) external {
    require(comments[_commentId].owner == msg.sender, "You must be the owner of the comment to delete it.");
    delete comments[_commentId];

    emit DeletedComment(_commentId);
}
