// app.js

// Initialize web3.js and the contract
const web3 = new Web3(window.ethereum);
const contract = new web3.eth.Contract(ABI, CONTRACT_ADDRESS);

// DOM elements
const connectWalletBtn = document.getElementById('connect-wallet');
const userProfile = document.getElementById('user-profile');
const createPostForm = document.getElementById('create-post-form');
const createPostInput = document.getElementById('create-post-input');
const postList = document.getElementById('post-list');
const loadMorePostsBtn = document.getElementById('load-more-posts');

// Global variables
let currentPostIndex = 0;
const postsPerPage = 10;

// Connect wallet and display user profile
async function connectWallet() {
  try {
    await window.ethereum.request({ method: 'eth_requestAccounts' });
    displayUserProfile();
  } catch (error) {
    console.error('Error connecting wallet:', error);
  }
}

async function displayUserProfile() {
  try {
    const accounts = await web3.eth.getAccounts();
    const account = accounts[0];
    const profile = await contract.methods.getUserProfile(account).call();
    userProfile.textContent = `${profile.name} (${profile.postsCount} posts)`;
  } catch (error) {
    console.error('Error displaying user profile:', error);
  }
}

// Fetch and display posts
async function fetchAndDisplayPosts() {
  try {
    const postIds = await contract.methods.getPostIds().call();
    const start = currentPostIndex;
    const end = currentPostIndex + postsPerPage;
    for (let i = start; i < end && i < postIds.length; i++) {
      const postId = postIds[i];
      const post = await contract.methods.getPost(postId).call();
      displayPost(post, postId);
    }
    currentPostIndex += postsPerPage;
  } catch (error) {
    console.error('Error fetching and displaying posts:', error);
  }
}

function displayPost(post, postId) {
  const postElement = document.createElement('div');
  postElement.className = 'post';
  postElement.dataset.postId = postId;

  const postContent = document.createElement('p');
  postContent.textContent = post.content;
  postElement.appendChild(postContent);

  const likeButton = document.createElement('button');
  likeButton.textContent = `Like (${post.likeCount})`;
  likeButton.addEventListener('click', () => toggleLikePost(postId, likeButton));
  postElement.appendChild(likeButton);

  const commentForm = document.createElement('form');
  const commentInput = document.createElement('input');
  commentInput.type = 'text';
  commentInput.placeholder = 'Add a comment';
  commentForm.appendChild(commentInput);

  const submitCommentButton = document.createElement('button');
  submitCommentButton.type = 'submit';
  submitCommentButton.textContent = 'Post';
  commentForm.appendChild(submitCommentButton);

  commentForm.addEventListener('submit', (event) => {
    event.preventDefault();
    submitComment(postId, commentInput.value);
  });

  postElement.appendChild(commentForm);

  postList.appendChild(postElement);
}

async function toggleLikePost(postId, likeButton) {
  try {
    const accounts = await web3.eth.getAccounts();
    const account = accounts[0];

    await contract.methods.toggleLikePost(postId).send({ from: account });

    // Update like count in the UI
    const postElement = document.querySelector(`.post[data-post-id="${postId}"]`);
    const likeCount = parseInt(likeButton.textContent.match(/\d+/)[0]) + 1;
    likeButton.textContent = `Like (${likeCount})`;
  } catch (error) {
console.error('Error toggling like on post:', error);
}
}

async function submitComment(postId, commentText) {
try {
const accounts = await web3.eth.getAccounts();
const account = accounts[0];

await contract.methods.submitComment(postId, commentText).send({ from: account });

// Clear the comment input
const postElement = document.querySelector(`.post[data-post-id="${postId}"]`);
const commentInput = postElement.querySelector('input');
commentInput.value = '';

} catch (error) {
console.error('Error submitting comment:', error);
}
}

// Event listeners
connectWalletBtn.addEventListener('click', connectWallet);

createPostForm.addEventListener('submit', async (event) => {
event.preventDefault();
const postContent = createPostInput.value;
try {
const accounts = await web3.eth.getAccounts();
const account = accounts[0];
await contract.methods.createPost(postContent).send({ from: account });
createPostInput.value = '';
} catch (error) {
console.error('Error creating post:', error);
}
});

loadMorePostsBtn.addEventListener('click', fetchAndDisplayPosts);

// Connect wallet and display user profile on page load
if (window.ethereum) {
window.ethereum.on('accountsChanged', displayUserProfile);
window.ethereum.on('chainChanged', () => {
window.location.reload();
});
connectWallet();
} else {
console.error('Non-Ethereum browser detected. Please install MetaMask.');
}

// Fetch and display initial posts on page load
window.addEventListener('DOMContentLoaded', fetchAndDisplayPosts);

