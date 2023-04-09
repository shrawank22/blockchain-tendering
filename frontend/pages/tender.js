import Head from 'next/head'
import { useState, useEffect } from 'react'
import Web3 from 'web3'
import tenderingContract from '../web3/main'
import 'bulma/css/bulma.css'
import styles from '../styles/Main.module.css'

const VendingMachine = () => {
  const [error, setError] = useState('')
  const [successMsg, setSuccessMsg] = useState('')
  const [web3, setWeb3] = useState(null)
  const [address, setAddress] = useState(null)
  const [tenderContract, settenderContract] = useState(null)
  const [partyCount, setPartyCount] = useState(0)
  const [partyName, setPartyName] = useState('');
  const [partyAddress, setPartyAddress] = useState('')

  useEffect(() => {
    if (tenderContract) 
      partyCountHandler()
    // if (tenderContract && address) 
    //   getProjectCountHandler()
  }, [tenderContract, address])

  const partyCountHandler = async () => {
    const partyCount = await tenderContract.methods.getPartyCount().call()
    setPartyCount(partyCount)
  }

  const updatePartyName = event => {
    setPartyName(event.target.value)
  }

  const updatePartyAddress = event => {
    setPartyAddress(event.target.value)
  }

  const createPartyHandler = async () => {
    try {
      console.log("Trying to create a party");
      await tenderContract.methods.createParty(partyName, partyAddress).send({
        from: address,
        // value: web3.utils.toWei('1', 'ether') * buyCount,
        // gas: 3000000,
        // gasPrice: null

      }),
        setSuccessMsg(`party created successfully`)
  
        if (tenderContract) partyCountHandler()
        // if (tenderContract && address) getProjectCountHandler()
    } catch (err) {
      setError(err.message)
    }
  }

  const connectWalletHandler = async () => {
    // checking  if MetaMask is available */
    if (typeof window !== "undefined" && typeof window.ethereum !== "undefined") {
      try {
        // request wallet connect
        await window.ethereum.request({ method: "eth_requestAccounts" })
        
        // creating web3 instance and set to state var
        const web3 = new Web3(window.ethereum)
        /* set web3 instance */
        setWeb3(web3)

        // Getting list of accounts
        const accounts = await web3.eth.getAccounts()

        // setting Account 1 to default account
        setAddress(accounts[0])

        // creating local contract copy
        const tc = tenderingContract(web3)
        settenderContract(tc)
      } catch (err) {
        setError(err.message)
      }
    } else {
      // metamask is not installed
      console.log("Please install MetaMask")
    }
  }

  return (
    <div className={styles.main}>
      <Head>
        <title>Tendering App</title>
        <meta name="description" content="A smart tendering/contracting application" />
      </Head>
      <nav className="navbar mt-4 mb-4">
        <div className="container">
          <div className="navbar-brand">
            <h1>Smart Tendering</h1>
          </div>
          <div className="navbar-end">
            <button onClick={connectWalletHandler} className="button is-primary">Connect Wallet</button>
          </div>
        </div>
      </nav>

      <section className='container'>
        <h2>Get Party Count {partyCount}</h2>
      </section>


      <section className='container'>
        <h2>Create Party</h2>
        <div className='field'>
          <label className='label'>Name</label>
          <div className='control'>
            <input onChange={updatePartyName} type='text' placeholder='Party Name' className='input' />
          </div>
          <label className='label'>PartyAddress</label>
          <div className='control'>
            <input onChange={updatePartyAddress} type='address' placeholder='Party Address' className='input' />
          </div>
          <button onClick={createPartyHandler}  className="button is-primary mt-2">Create</button>
        </div>
      </section>

      {/* <section className="mt-5">
        <div className="container">
          <div className="field">
          <label className="label">Name</label>
            <div className="control">
              <input className="input" type="text" placeholder="Your Name" />
            </div>
            <label className="label">Username</label>
            <div className="control">
              <input className="input" type="text" placeholder="Username" />
            </div>
            <label className="label">Email</label>
            <div className="control">
              <input className="input" type="email" placeholder="Email" />
            </div>
            <label className="label">Password</label>
            <div className="control">
              <input className="input" type="password" placeholder="Password" />
            </div>
            <label className="label">Confirm Password</label>
            <div className="control">
              <input className="input" type="password" placeholder="Confirm Password" />
            </div>
            <button
              className="button is-primary mt-2">
              Register
            </button>
          </div>
        </div>
      </section> */}

      <section>
        <div className="container has-text-danger">
          <p>{error}</p>
        </div>
      </section>
      <section>
        <div className="container has-text-success">
          <p>{successMsg}</p>
        </div>
      </section>
    </div>
  )
}

export default VendingMachine