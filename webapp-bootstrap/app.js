const contracts = {
    31337: "0x8488A9536320Cc11D61c8681c09A726318C167f3",
};


const txOptions = {
    gasLimit: 1 * 10**6
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

async function connectWallet() {
    if (window.ethereum) {
        try {
            // Request account access
            const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
            return accounts[0];  // Return the first account address
        } catch (error) {
            console.error("User denied account access");
        }
    } else {
        alert('Please install MetaMask or another web3 provider.');
    }
}

document.addEventListener('DOMContentLoaded', async () => {
    await connectWallet();

    const provider = new ethers.providers.Web3Provider(window.ethereum, "any");
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
    const assetTokenContract = new ethers.Contract(await assetManagerContract.asset(), ERC20_ABI, signer);

    async function updateWalletInfo() {
        const network = await provider.getNetwork()

        document.getElementById("connectWalletBtn").hidden = true;
        document.getElementById("walletInfo").innerText = walletAddress;
        document.getElementById("networkInfo").innerText = `${network.chainId}/${network.name}`;
    }
    updateWalletInfo();

    // Fetch balance and display
    async function fetchShares() {
        const balance = await assetManagerContract.balanceOf(walletAddress);
        const total = await assetManagerContract.totalSupply();
        const symbol = await assetManagerContract.symbol();
        document.getElementById('shares').innerText = ethers.utils.formatEther(balance) + "/" + ethers.utils.formatEther(total) + " " + symbol;
    }

    // Fetch balance and display
    async function fetchAssets() {
        const balance = await assetManagerContract.totalAssets();
        const symbol = await assetTokenContract.symbol();
        document.getElementById('assets').innerText = ethers.utils.formatEther(balance) + " " + symbol;
    }

    async function fetchBalance() {
        const balance = await assetTokenContract.balanceOf(walletAddress);
        const symbol = await assetTokenContract.symbol();
        document.getElementById('balance').innerText = ethers.utils.formatEther(balance) + " " + symbol;
    }

    async function fetchBalances() {
        fetchAssets();
        fetchShares();
        fetchBalance();
        updateVaultsTable();
    }

    fetchBalances();

    setInterval(() => {
        fetchBalances();
    }, 5000);

    // Reinvest
    document.getElementById('reinvestBtn').addEventListener('click', async () => {
        try {
            const tx = await assetManagerContract.reinvest(txOptions);
            await tx.wait();
            fetchBalances();
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
            fetchBalances();
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
            fetchBalances();
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
            fetchBalances();
        } catch (error) {
            console.error("Redeem failed:", error);
            alert(JSON.stringify(error));
        }
    });

    // Connect Wallet button event listener
    document.getElementById('connectWalletBtn').addEventListener('click', async () => {
        await connectWallet();
        fetchBalances();
    });

    async function updateVaultsTable() {
        const tableBody = document.getElementById('vaultsTable');

        // Clear any existing rows
        tableBody.innerHTML = "";

        // Fetch the vaults
        const vaultAddresses = await assetManagerContract.getVaults();
        const totalAssets = await assetManagerContract.totalAssets();

        for (let address of vaultAddresses) {
            // Create ERC4626 contract instance
            const vault = new ethers.Contract(address, ERC4626_ABI, signer); // Ensure you have the ABI for ERC4626

            // Fetch the necessary data
            const name = await vault.name();
            const symbol = await vault.symbol();
            const vaultTotalShares = await vault.totalSupply();
            const vaultTotalAssets =await vault.totalAssets();
            const vaultSharePrice = vaultTotalAssets / vaultTotalShares;

            const vaultOurShares = await vault.balanceOf(contractAddress);
            const vaultOurAssets = vaultSharePrice * vaultOurShares;

            let holdingPercentage = 0;
            if (totalAssets > 0) {
                holdingPercentage = (vaultOurAssets / totalAssets) * 100;
            }

            // Add a row to the table
            const row = `<tr>
                <td>${name}</td>
                <td>${symbol}</td>
                <td>${ethers.utils.formatEther(vaultTotalShares)}</td>
                <td>${ethers.utils.formatEther(vaultTotalAssets)}</td>
                <td>${ethers.utils.formatEther(vaultOurShares)}</td>
                <td>${holdingPercentage.toFixed(2)}%</td>
                <td><button id="deleteButton" class="btn btn-danger mt-2">Delete</button></td>

            </tr>`;

            tableBody.innerHTML += row;
        }
    }

});
