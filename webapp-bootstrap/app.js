const contracts = {
    31337: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
};


const txOptions = {
    gasLimit: 1 * 10 ** 6
};

const ERC4626_ABI = [
    "function reinvest() public returns (uint256)",
    "function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets)",
    "function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares)",
    "function deposit(uint256 assets, address receiver) external returns (uint256 shares)",
    "function totalAssets() external view returns (uint256 totalManagedAssets)",
    "function asset() external view returns (address assetTokenAddress)",
    "function totalSupply() external view returns (uint256)",
    "function balanceOf(address account) external view returns (uint256)",
    "function name() external view returns (string memory)",
    "function symbol() external view returns (string memory)",
    "function getVaults() public view returns (address[] memory)",
    "function convertToAssets(uint256 shares) external view returns (uint256 assets)"
];

const ERC20_ABI = [
    "function totalSupply() external view returns (uint256)",
    "function balanceOf(address account) external view returns (uint256)",
    "function name() external view returns (string memory)",
    "function symbol() external view returns (string memory)"
];


// returns provider
async function connectWallet() {
    if (window.ethereum) {
        try {
            // Request account access
            const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
            console.log("Connected to the wallet", accounts);
            return new ethers.providers.Web3Provider(window.ethereum, "any");
        } catch (error) {
            console.error("User denied account access");
        }
    } else {
        alert('Please install MetaMask or another web3 provider.');
    }
}

document.addEventListener('DOMContentLoaded', async () => {
    const provider = await connectWallet();

    provider.on("network", (newNetwork, oldNetwork) => {
        console.log("Switching from ", oldNetwork, "to", newNetwork);
        if (oldNetwork) {
            window.location.reload();
        }
    });

 
    const signer = provider.getSigner();
    const walletAddress = await signer.getAddress();
    const contractAddress = contracts[(await provider.getNetwork()).chainId];
    if (!contractAddress) {
        alert("This network is not supported");
        return;
    }

    const assetManagerContract = new ethers.Contract(contractAddress, ERC4626_ABI, signer);
    const assetSymbol = await assetManagerContract.asset();
    const assetTokenContract = new ethers.Contract(assetSymbol, ERC20_ABI, signer);

    // Fetch balance and display
    async function fetchShares() {
        const balance = await assetManagerContract.balanceOf(walletAddress);
        const total = await assetManagerContract.totalSupply();
        const symbol = await assetManagerContract.symbol();
        updateShares(balance, total, symbol);
    }

    // Fetch balance and display
    async function fetchAssets() {
        const balance = await assetManagerContract.totalAssets();
        const symbol = await assetTokenContract.symbol();
        updateInvestedAssets(balance, symbol);
    }

    async function fetchBalance() {
        const balance = await assetTokenContract.balanceOf(walletAddress);
        const symbol = await assetTokenContract.symbol();
        updateNonInvestedAssets(balance, symbol);
    }

    async function fetchAll() {
        fetchAssets();
        fetchShares();
        fetchBalance();
        updateVaultsTable();
    }

    await fetchAll();
    setInterval(() => {
        fetchAll();
    }, 5000);

    // Reinvest
    document.getElementById('reinvestBtn').addEventListener('click', async () => {
        try {
            const tx = await assetManagerContract.reinvest(txOptions);
            await tx.wait();
            fetchAll();
        } catch (error) {
            // console.error("Reinvest failed:", error);
            // alert(JSON.stringify(error));
        }

        alert("Reinvested");
    });

    // Deposit
    document.getElementById('depositBtn').addEventListener('click', async () => {
        const amount = ethers.utils.parseEther(document.getElementById('amountInput').value);
        try {
            const tx = await assetManagerContract.deposit(amount, await signer.getAddress());
            await tx.wait();
            fetchAll();
        } catch (error) {
            console.error("Deposit failed:", error);
            alert(JSON.stringify(error));
        }
    });

    // Withdraw
    document.getElementById('withdrawBtn').addEventListener('click', async () => {
        const amount = ethers.utils.parseEther(document.getElementById('amountInput').value);
        try {
            const tx = await assetManagerContract.withdraw(amount, await signer.getAddress(), await signer.getAddress(), txOptions);
            await tx.wait();
            fetchAll();
        } catch (error) {
            console.error("Withdraw failed:", error);
            alert(JSON.stringify(error));
        }
    });

    // Redeem
    document.getElementById('redeemBtn').addEventListener('click', async () => {
        const shares = ethers.utils.parseEther(document.getElementById('amountInput').value);
        try {
            const tx = await assetManagerContract.redeem(shares, await signer.getAddress(), await signer.getAddress(), txOptions);
            await tx.wait();
            fetchAll();
        } catch (error) {
            console.error("Redeem failed:", error);
            alert(JSON.stringify(error));
        }
    });


    async function updateVaultsTable() {
        // Fetch the vaults
        const vaultAddresses = await assetManagerContract.getVaults();
        const totalAssets = await assetManagerContract.totalAssets();
        let items = [];

        for (let address of vaultAddresses) {
            // Create ERC4626 contract instance
            const vault = new ethers.Contract(address, ERC4626_ABI, signer); // Ensure you have the ABI for ERC4626

            // Fetch the necessary data
            const name = await vault.name();
            const symbol = await vault.symbol();
            const vaultTotalShares = await vault.totalSupply();
            const vaultTotalAssets = await vault.totalAssets();
            const vaultSharePrice = vaultTotalAssets / vaultTotalShares;

            const vaultOurShares = await vault.balanceOf(contractAddress);
            const vaultOurAssets = vaultSharePrice * vaultOurShares;

            let holdingPercentage = 0;
            if (totalAssets > 0) {
                holdingPercentage = (vaultOurAssets / totalAssets) * 100;
            }

            items.push({
                name, symbol, vaultTotalShares, vaultTotalAssets, vaultSharePrice, vaultOurShares, vaultOurAssets,  holdingPercentage
            });
        }
        updateVaults(items);
    }

});
